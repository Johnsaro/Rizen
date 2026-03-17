import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_data.dart';
import '../models/quest.dart';
import '../models/game_notification.dart';
import '../models/achievement.dart';
import '../models/personal_record.dart';
import 'supabase_service.dart';

/// Central game state manager. All mutations to playerNotifier, questNotifier,
/// guildBoardNotifier, and checkedInNotifier must go through this class.
///
/// Resolves userId dynamically from the current Supabase session, so re-auth
/// and multi-account sign-out/sign-in are handled automatically.
class GameService {
  final ValueNotifier<PlayerData> playerNotifier;
  final ValueNotifier<List<Quest>> questNotifier;
  final ValueNotifier<List<Quest>> guildBoardNotifier;
  final ValueNotifier<bool> checkedInNotifier;
  final ValueNotifier<List<GameNotification>> notificationsNotifier;
  final ValueNotifier<List<PersonalRecord>> prNotifier;

  final errorNotifier = ValueNotifier<String?>(null);
  final isLoadingNotifier = ValueNotifier<bool>(false);

  // Service-level reentrancy guards — prevent duplicate mutations
  // even when triggered from multiple UI code paths simultaneously.
  final Set<String> _completingQuestIds = {};
  final Set<String> _consumingItems = {};
  final Set<String> _purchasingItems = {};

  GameService({
    required this.playerNotifier,
    required this.questNotifier,
    required this.guildBoardNotifier,
    required this.checkedInNotifier,
    required this.notificationsNotifier,
    required this.prNotifier,
  });

  String get _userId {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }
  bool get _hasSession => _userId.isNotEmpty;

  // ── Load all data on startup ─────────────────────────────

  Future<void> loadAll() async {
    if (!_hasSession) return;
    isLoadingNotifier.value = true;
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().substring(0, 10);

      var result = await SupabaseService.loadProfile(_userId);

      // Web-registered users have auth metadata (full_name, class) but no
      // profile row yet. Auto-create their profile so they skip GM onboarding.
      if (result == null) {
        final meta =
            Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
        final webName = (meta['full_name'] as String?)?.trim() ?? '';
        final webClass = (meta['class'] as String?)?.trim() ?? '';

        if (webName.isNotEmpty) {
          final webPlayer = PlayerData(
            name: webName,
            mainClass: webClass.isNotEmpty ? webClass : 'Web Developer',
            sideClass: 'Sec Analyst',
          );
          await SupabaseService.saveProfile(
            _userId,
            webPlayer,
            onboardingComplete: true,
          );
          // Re-load so the rest of loadAll sees the freshly created row
          result = await SupabaseService.loadProfile(_userId);
        }
      }

      if (result != null) {
        var player = result.player;
        final lastCheckin = result.checkedInDate;
        checkedInNotifier.value = lastCheckin == today;

        // Daily reset for guild board: if last checkin was not today, clear local board
        if (lastCheckin != today) {
          guildBoardNotifier.value = [];
        }

        // Streak break detection — only when there's a prior checkin and it's not today
        if (lastCheckin.isNotEmpty && lastCheckin != today) {
          final lastDate = DateTime.tryParse(lastCheckin);
          if (lastDate == null) {
            debugPrint('Invalid checkedInDate format: $lastCheckin — skipping streak check');
          } else {
            final todayDate = DateTime(now.year, now.month, now.day);
            final dayDiff = todayDate.difference(lastDate).inDays;
            final missedDays = dayDiff - 1; // gap of 2 days = 1 missed day

            if (missedDays > 0) {
              int streak = player.streak;
              int shields = player.shields;

              // Consume shields first, then break streak only if they ran out
              final consumed = shields > missedDays ? missedDays : shields;
              shields -= consumed;
              if (missedDays > consumed) {
                streak = 0;
              }

              if (streak != player.streak || shields != player.shields) {
                final penalized = player.copyWith(streak: streak, shields: shields);
                // Only commit penalty if Supabase write succeeds — prevents double-deduction on crash
                try {
                  await SupabaseService.saveProfile(_userId, penalized);
                  player = penalized;
                  _createNotification(
                    '"Your streak has broken. The foundation cracks. Begin again — stronger."',
                    NotificationType.streakBreak,
                  );
                } catch (_) {
                  errorNotifier.value = 'Failed to process streak. Check your connection.';
                }
              }
            }
          }
        }

        // Validate featured achievement — clear if not actually earned
        if (player.featuredAchievement.isNotEmpty &&
            !player.achievements.containsKey(player.featuredAchievement)) {
          player = player.copyWith(featuredAchievement: '');
        }

        // Clean expired buffs on load and persist if any were removed.
        // Always use cleaned state locally — even if DB save fails, expired
        // buffs return false from isBuffActive() so gameplay is unaffected.
        // The save is best-effort to keep DB in sync.
        final cleaned = player.cleanExpiredBuffs();
        if (!identical(cleaned, player)) {
          player = cleaned;
          try {
            await SupabaseService.saveProfile(_userId, player);
          } catch (e) {
            debugPrint('Failed to persist cleaned buffs: $e');
          }
        }
        playerNotifier.value = player;
      }

      final quests = await SupabaseService.loadQuests(_userId);
      if (quests.isNotEmpty) {
        questNotifier.value = quests;
      } else {
        // New user — start with an empty board; quests come from the Guild Master
        questNotifier.value = [];
      }

      // Quest expiry check
      await _checkExpiredQuests(today);

      final guildBoard = await SupabaseService.loadGuildBoard(_userId, today);
      guildBoardNotifier.value = guildBoard;

      final notifications = await SupabaseService.loadNotifications(_userId);
      notificationsNotifier.value = notifications;

      final prs = await SupabaseService.loadPersonalRecords(_userId);
      prNotifier.value = prs;
    } catch (e) {
      errorNotifier.value = 'Failed to load data. Check your connection.';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // ── Complete a quest ─────────────────────────────────────

  Future<bool> completeQuest(Quest quest) async {
    if (!_hasSession) return false;
    if (_completingQuestIds.contains(quest.id)) return false;
    _completingQuestIds.add(quest.id);

    try {
      // Snapshot both touched notifiers before any mutation
      final prevPlayer = playerNotifier.value;
      final prevQuests = questNotifier.value;

      // Validate quest is in the active list and not already completed
      final activeQuest = prevQuests.where((q) => q.id == quest.id).firstOrNull;
      if (activeQuest == null || activeQuest.isCompleted) return false;

      final repGain = (quest.xpReward * 0.1).round();
      final updatedQuests = prevQuests
          .map((q) => q.id == quest.id ? q.copyWith(isCompleted: true) : q)
          .toList();
      var updatedPlayer = _awardXPAndRep(
        prevPlayer,
        quest.xpReward,
        repGain,
        classTag: quest.classTag,
        isQuestReward: true,
      );
      // Consume XP Surge AFTER multiplier was applied but BEFORE save —
      // this way rollback to prevPlayer still has the surge intact.
      if (prevPlayer.isBuffActive('XP Surge')) {
        final cleanedBuffs = Map<String, String>.from(updatedPlayer.activeBuffs)
          ..remove('XP Surge');
        updatedPlayer = updatedPlayer.copyWith(activeBuffs: cleanedBuffs);
      }
      updatedPlayer = updatedPlayer.copyWith(
        questsCompleted: updatedPlayer.questsCompleted + 1,
      );
      final newAchievements = <String>[];
      updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);

      playerNotifier.value = updatedPlayer;
      questNotifier.value = updatedQuests;

      try {
        // Save quests first — if this fails, profile (with consumed surge) is never written
        await SupabaseService.saveQuests(_userId, updatedQuests);
        await SupabaseService.saveProfile(_userId, updatedPlayer);

        // Notifications — fire-and-forget, do not affect rollback
        _createNotification(
          '"Quest complete. ${quest.title} — ${quest.xpReward} XP claimed."',
          NotificationType.questComplete,
        );
        if (updatedPlayer.level > prevPlayer.level) {
          _createNotification(
            '"You have advanced to Level ${updatedPlayer.level}. The guild takes notice."',
            NotificationType.levelUp,
          );
        }
        _notifyAchievements(newAchievements);
        return true;
      } catch (e) {
        // Restore both snapshots on any failure
        playerNotifier.value = prevPlayer;
        questNotifier.value = prevQuests;
        errorNotifier.value = 'Failed to save quest completion. Try again.';
        return false;
      }
    } finally {
      _completingQuestIds.remove(quest.id);
    }
  }

  // ── Accept a quest ───────────────────────────────────────

  Future<void> acceptQuest(Quest quest) async {
    if (!_hasSession) return;
    if (questNotifier.value.any((q) => q.id == quest.id)) return;
    final prevQuests = questNotifier.value;

    // Set deadline based on quest type
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final deadline = quest.type == 'main'
        ? DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10)
        : today;
    final questWithDeadline = quest.copyWith(deadline: deadline);

    final updatedQuests = [...prevQuests, questWithDeadline];
    questNotifier.value = updatedQuests;

    try {
      await SupabaseService.saveQuests(_userId, updatedQuests);
    } catch (e) {
      questNotifier.value = prevQuests;
      errorNotifier.value = 'Failed to accept quest. Try again.';
    }
  }

  // ── Add guild board quests ───────────────────────────────

  Future<void> addGuildBoardQuests(List<Quest> quests) async {
    if (!_hasSession) return;
    final prevBoard = guildBoardNotifier.value;
    final newQuests =
        quests.where((q) => !prevBoard.any((b) => b.id == q.id)).toList();
    if (newQuests.isEmpty) return;

    final updatedBoard = [...prevBoard, ...newQuests];
    guildBoardNotifier.value = updatedBoard;

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await SupabaseService.saveGuildBoard(_userId, updatedBoard, today);
    } catch (e) {
      guildBoardNotifier.value = prevBoard;
      errorNotifier.value = 'Failed to save guild board. Try again.';
    }
  }

  // ── Guild Hall check-in ──────────────────────────────────

  Future<void> checkIn() async {
    if (!_hasSession) return;
    // Snapshot both touched notifiers before any mutation
    final prevPlayer = playerNotifier.value;
    final prevCheckedIn = checkedInNotifier.value;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final newStreak = prevPlayer.streak + 1;

    // Milestone rewards — re-trigger on every rebuild (simpler, more motivating)
    int bonusRep = 0;
    int bonusShields = 0;
    if (newStreak == 7)   { bonusRep = 200;   bonusShields = 1; }
    if (newStreak == 30)  { bonusRep = 500; }
    if (newStreak == 60)  { bonusRep = 1000; }
    if (newStreak == 100) { bonusRep = 2000; }
    if (newStreak == 365) { bonusRep = 2000; }

    // Base check-in rewards: +50 XP, +5 Rep (+ any milestone bonus)
    var updatedPlayer = _awardXPAndRep(prevPlayer, 50, 5 + bonusRep, classTag: 'Any');
    final newShields = (updatedPlayer.shields + bonusShields).clamp(0, 3);
    updatedPlayer = updatedPlayer.copyWith(streak: newStreak, shields: newShields);
    final newAchievements = <String>[];
    updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);

    playerNotifier.value = updatedPlayer;
    checkedInNotifier.value = true;

    try {
      await SupabaseService.saveProfile(_userId, updatedPlayer, checkinDate: today);

      // Notifications — fire-and-forget
      _createNotification(
        '"You have arrived. The guild acknowledges your presence."',
        NotificationType.checkin,
      );
      if (bonusRep > 0) {
        _createNotification(
          '"$newStreak day streak. The guild recognizes your dedication. +$bonusRep Rep awarded."',
          NotificationType.streakMilestone,
        );
      }
      if (updatedPlayer.level > prevPlayer.level) {
        _createNotification(
          '"You have advanced to Level ${updatedPlayer.level}. The guild takes notice."',
          NotificationType.levelUp,
        );
      }
      _notifyAchievements(newAchievements);
    } catch (e) {
      // Restore both on failure
      playerNotifier.value = prevPlayer;
      checkedInNotifier.value = prevCheckedIn;
      errorNotifier.value = 'Check-in failed. Try again.';
    }
  }

  // ── Shop purchase ────────────────────────────────────────

  Future<void> purchaseItem(String itemName, int cost) async {
    if (!_hasSession) return;
    if (_purchasingItems.contains(itemName)) return;
    _purchasingItems.add(itemName);

    try {
      final prevPlayer = playerNotifier.value;

      // Ownership guard — prevent duplicate purchase of the same item
      if (prevPlayer.inventory.containsKey(itemName) &&
          (prevPlayer.inventory[itemName] ?? 0) > 0) {
        return;
      }

      var updatedPlayer = prevPlayer.buyItem(itemName, cost);
      final newAchievements = <String>[];
      updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);
      playerNotifier.value = updatedPlayer;

      try {
        await SupabaseService.saveProfile(_userId, updatedPlayer);
        _notifyAchievements(newAchievements);
      } catch (e) {
        playerNotifier.value = prevPlayer;
        errorNotifier.value = 'Purchase failed. Try again.';
      }
    } finally {
      _purchasingItems.remove(itemName);
    }
  }

  // ── Use consumable item ─────────────────────────────────

  /// Activates a consumable item. Returns an error message if blocked, or null on success.
  Future<String?> useItem(String itemName) async {
    if (!_hasSession) return 'No session';
    if (_consumingItems.contains(itemName)) return 'Already in progress';
    _consumingItems.add(itemName);

    try {
      final prevPlayer = playerNotifier.value;
      final count = prevPlayer.inventory[itemName] ?? 0;
      if (count <= 0) return 'You don\'t have any $itemName';

      PlayerData updatedPlayer;

      switch (itemName) {
        case 'Health Potion':
          if (prevPlayer.maxHp <= 0) return 'Cannot use — max HP is invalid';
          if (prevPlayer.hp >= prevPlayer.maxHp) return 'HP is already full';
          final newHp = (prevPlayer.hp + 300).clamp(0, prevPlayer.maxHp);
          updatedPlayer = prevPlayer.useInstantItem(itemName).copyWith(hp: newHp);

        case 'Shield Charge':
          if (prevPlayer.shields >= 3) return 'Shields already at max (3)';
          updatedPlayer = prevPlayer.useInstantItem(itemName)
              .copyWith(shields: (prevPlayer.shields + 1).clamp(0, 3));

        case 'Focus Boost':
          if (prevPlayer.isBuffActive('Focus Boost')) return 'Focus Boost is already active';
          updatedPlayer = prevPlayer.activateBuff('Focus Boost', itemName, const Duration(hours: 2));

        case 'Double Rep':
          if (prevPlayer.isBuffActive('Double Rep')) return 'Double Rep is already active';
          updatedPlayer = prevPlayer.activateBuff('Double Rep', itemName, const Duration(hours: 1));

        case 'XP Surge':
          if (prevPlayer.isBuffActive('XP Surge')) return 'XP Surge is already active';
          updatedPlayer = prevPlayer.activateXPSurge();

        case 'Durability Kit':
        case 'Time Warp':
          return 'Coming soon — not yet implemented';

        default:
          return 'Unknown item';
      }

      playerNotifier.value = updatedPlayer;

      try {
        await SupabaseService.saveProfile(_userId, updatedPlayer);
        _createNotification(
          '"$itemName activated. Use it wisely."',
          NotificationType.info,
        );
        return null;
      } catch (e) {
        playerNotifier.value = prevPlayer;
        errorNotifier.value = 'Failed to use item. Try again.';
        return 'Failed to save';
      }
    } finally {
      _consumingItems.remove(itemName);
    }
  }

  // ── Update player directly (onboarding, profile edits) ──

  Future<void> updatePlayer(
    PlayerData updated, {
    String? checkinDate,
    bool? onboardingComplete,
  }) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;
    playerNotifier.value = updated;

    try {
      await SupabaseService.saveProfile(
        _userId,
        updated,
        checkinDate: checkinDate,
        onboardingComplete: onboardingComplete,
      );
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to save profile. Try again.';
    }
  }

  // ── Equip weapon ─────────────────────────────────────────

  /// Sets [weaponName] as the player's equipped weapon.
  /// Pass an empty string to unequip.
  Future<void> equipWeapon(String weaponName) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;
    final updatedPlayer = prevPlayer.copyWith(equippedWeapon: weaponName);
    playerNotifier.value = updatedPlayer;

    try {
      await SupabaseService.saveProfile(_userId, updatedPlayer);
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to save loadout. Try again.';
    }
  }

  // ── Equip cosmetic ───────────────────────────────────────

  /// Equips [itemName] into [category] (e.g., Theme, Frame, Effect).
  /// Pass an empty string for [itemName] to unequip that category.
  Future<void> equipCosmetic(String category, String itemName) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;

    // Ownership check — only allow equipping items the player actually owns
    if (itemName.isNotEmpty && !prevPlayer.inventory.containsKey(itemName)) {
      errorNotifier.value = 'You don\'t own that cosmetic.';
      return;
    }

    final newCosmetics = Map<String, String>.from(prevPlayer.equippedCosmetics);

    if (itemName.isEmpty) {
      newCosmetics.remove(category);
    } else {
      newCosmetics[category] = itemName;
    }
    
    final updatedPlayer = prevPlayer.copyWith(equippedCosmetics: newCosmetics);
    playerNotifier.value = updatedPlayer;

    try {
      await SupabaseService.saveProfile(_userId, updatedPlayer);
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to equip cosmetic. Try again.';
    }
  }

  // ── Combat outcomes ──────────────────────────────────────

  /// Victory: award XP (routes to the class the player fought for), restore HP.
  Future<void> applyCombatVictory(int xpReward, String classTag) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;

    var updatedPlayer = _awardXPAndRep(prevPlayer, xpReward, 0, classTag: classTag, isQuestReward: true);
    // Consume XP Surge after multiplier applied — rollback to prevPlayer preserves it
    if (prevPlayer.isBuffActive('XP Surge')) {
      final cleanedBuffs = Map<String, String>.from(updatedPlayer.activeBuffs)
        ..remove('XP Surge');
      updatedPlayer = updatedPlayer.copyWith(activeBuffs: cleanedBuffs);
    }
    updatedPlayer = updatedPlayer.copyWith(
      hp: updatedPlayer.maxHp,
      monstersKilled: updatedPlayer.monstersKilled + 1,
    );
    final newAchievements = <String>[];
    updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);
    playerNotifier.value = updatedPlayer;

    try {
      await SupabaseService.saveProfile(_userId, updatedPlayer);
      if (xpReward > 0) {
        _createNotification(
          '"Monster defeated. +$xpReward XP claimed. HP restored."',
          NotificationType.combatVictory,
        );
      }
      if (updatedPlayer.level > prevPlayer.level) {
        _createNotification(
          '"You have advanced to Level ${updatedPlayer.level}. The guild takes notice."',
          NotificationType.levelUp,
        );
      }
      _notifyAchievements(newAchievements);
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to save combat result. Try again.';
    }
  }

  /// Flee: deduct flat XP penalty, restore HP (no wound carry-forward).
  Future<void> applyCombatFlee(int xpPenalty) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;
    final newXP = (prevPlayer.currentXP - xpPenalty).clamp(0.0, prevPlayer.currentXP);
    final updatedPlayer = prevPlayer.copyWith(currentXP: newXP, hp: prevPlayer.maxHp);
    playerNotifier.value = updatedPlayer;

    try {
      await SupabaseService.saveProfile(_userId, updatedPlayer);
      _createNotification(
        '"You fled the battle. Cowardice costs you. -$xpPenalty XP."',
        NotificationType.info,
      );
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to save combat result. Try again.';
    }
  }

  /// Defeat: deduct XP (pre-computed by CombatService at fight-end), restore HP.
  Future<void> applyCombatDeath(int xpLoss) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;

    final newXP = (prevPlayer.currentXP - xpLoss).clamp(0.0, prevPlayer.currentXP);
    final updatedPlayer = prevPlayer.copyWith(currentXP: newXP, hp: prevPlayer.maxHp);
    playerNotifier.value = updatedPlayer;

    try {
      await SupabaseService.saveProfile(_userId, updatedPlayer);
      _createNotification(
        '"You have been defeated. -$xpLoss XP lost. The guild awaits your return."',
        NotificationType.streakBreak,
      );
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to save combat result. Try again.';
    }
  }

  // ── Quest expiry ─────────────────────────────────────────

  Future<void> _checkExpiredQuests(String today) async {
    final allQuests = questNotifier.value;
    final expired = <Quest>[];

    for (final quest in allQuests) {
      if (quest.isCompleted || quest.deadline.isEmpty) continue;
      try {
        final deadlineDate = DateTime.parse(quest.deadline);
        final todayDate = DateTime.parse(today);
        if (deadlineDate.isBefore(todayDate)) expired.add(quest);
      } catch (_) {
        // Malformed deadline — treat as expired so the quest doesn't hang forever
        expired.add(quest);
      }
    }

    if (expired.isEmpty) return;

    final expiredIds = expired.map((q) => q.id).toSet();
    var updatedQuests = allQuests.where((q) => !expiredIds.contains(q.id)).toList();
    var updatedPlayer = playerNotifier.value;

    for (final quest in expired) {
      if (quest.type == 'main') {
        updatedPlayer = _applyMainQuestPenalty(updatedPlayer);
      }
    }

    try {
      await SupabaseService.saveQuests(_userId, updatedQuests);
      await SupabaseService.saveProfile(_userId, updatedPlayer);
      questNotifier.value = updatedQuests;
      playerNotifier.value = updatedPlayer;
      for (final quest in expired) {
        if (quest.type == 'main') {
          _createNotification(
            '"You have failed a main quest. The guild is disappointed."',
            NotificationType.streakBreak,
          );
        } else {
          _createNotification(
            '"A quest has slipped away. The guild clears it from your board."',
            NotificationType.info,
          );
        }
      }
    } catch (_) {
      errorNotifier.value = 'Failed to process expired quests. Check your connection.';
    }
  }

  PlayerData _applyMainQuestPenalty(PlayerData player) {
    final newXP = (player.currentXP * 0.6).floorToDouble();
    final bottomed = player.level == 1 && newXP == 0;
    return player.copyWith(
      currentXP: newXP,
      title: bottomed ? 'Lazy Sloth Slave' : player.title,
    );
  }

  // ── Clear notifications ──────────────────────────────────

  Future<void> clearNotifications() async {
    if (!_hasSession) return;
    final prev = notificationsNotifier.value;
    notificationsNotifier.value = [];
    try {
      await SupabaseService.clearNotifications(_userId);
    } catch (e) {
      notificationsNotifier.value = prev;
      errorNotifier.value = 'Failed to clear notifications. Try again.';
    }
  }

  // ── Personal Records ────────────────────────────────────

  /// Creates a new personal record. Insert-first: no local change on failure.
  /// Returns true on success, false on failure or rate limit.
  Future<bool> createPersonalRecord({
    required String title,
    required String category,
    String description = '',
    String mood = '',
    String? metricType,
    String? metricValue,
    List<String> tags = const [],
  }) async {
    if (!_hasSession) return false;

    // 3/day client-side rate limit
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCount = prNotifier.value
        .where((pr) {
          final prDay = DateTime(pr.createdAt.year, pr.createdAt.month, pr.createdAt.day);
          return prDay == today;
        })
        .length;
    if (todayCount >= 3) {
      errorNotifier.value = 'You can log up to 3 PRs per day. Come back tomorrow.';
      return false;
    }

    try {
      final record = await SupabaseService.addPersonalRecord(
        _userId,
        title: title,
        category: category,
        description: description,
        mood: mood,
        metricType: metricType,
        metricValue: metricValue,
        tags: tags,
        streakContext: playerNotifier.value.streak,
      );
      prNotifier.value = [record, ...prNotifier.value];
      _createNotification(
        '"New record logged: $title"',
        NotificationType.achievement,
      );
      return true;
    } catch (e) {
      errorNotifier.value = 'Failed to log PR. Check your connection.';
      return false;
    }
  }

  // ── Private helpers ──────────────────────────────────────

  /// Centralises XP + Rep arithmetic so all reward paths use the same logic.
  /// Applies active buff multipliers (Focus Boost, XP Surge, Double Rep).
  /// Set [isQuestReward] to true when called from quest completion or combat
  /// victory — only those paths apply the XP Surge multiplier.
  ///
  /// NOTE: This method no longer removes XP Surge from activeBuffs. Callers
  /// that consume surge must remove it themselves BEFORE the Supabase save,
  /// so that a failed save + rollback preserves the buff correctly.
  PlayerData _awardXPAndRep(
    PlayerData player,
    int xp,
    int rep, {
    String classTag = 'Any',
    bool isQuestReward = false,
  }) {
    double xpMultiplier = 1.0;
    double repMultiplier = 1.0;

    if (player.isBuffActive('Focus Boost')) {
      xpMultiplier += 0.5;
    }
    if (player.isBuffActive('XP Surge') && isQuestReward) {
      xpMultiplier += 1.0;
    }
    if (player.isBuffActive('Double Rep')) {
      repMultiplier += 1.0;
    }

    final effectiveXP = (xp * xpMultiplier).round();
    final effectiveRep = (rep * repMultiplier).round();

    return player
        .addXP(effectiveXP, classTag: classTag)
        .addRep(effectiveRep);
  }

  /// Creates a notification locally and persists it to Supabase.
  /// Failures are non-fatal — core game state is never rolled back for a notification.
  void _createNotification(String message, NotificationType type) {
    final notif = GameNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    notificationsNotifier.value = [notif, ...notificationsNotifier.value];

    SupabaseService.addNotification(_userId, message, type).catchError((_) {
      // Non-fatal — notification dropped silently
    });
  }

  // ── Achievement checking ───────────────────────────────

  /// Compares state to detect newly earned achievements.
  /// Returns updated PlayerData with unlocked achievements, Rep, and titles applied.
  /// Newly unlocked IDs are collected in [newUnlocks] so callers can fire
  /// notifications AFTER the Supabase write succeeds.
  PlayerData _checkAndUnlockAchievements(PlayerData player, {List<String>? newUnlocks}) {
    var updated = player;
    final achievements = Map<String, String>.from(updated.achievements);
    final now = DateTime.now().toUtc().toIso8601String();

    void unlock(String id) {
      if (achievements.containsKey(id)) return;
      final a = AchievementCatalog.get(id);
      if (a == null || a.comingSoon) return;
      achievements[id] = now;
      newUnlocks?.add(id);
      if (a.repReward > 0) {
        updated = updated.copyWith(achievements: achievements).addRep(a.repReward);
      }
      if (a.titleReward != null) {
        updated = updated.copyWith(title: a.titleReward, achievements: achievements);
      }
    }

    // ── Consistency (streak) ──────────────────────────────
    if (updated.streak >= 1)   unlock('first_step');
    if (updated.streak >= 7)   unlock('the_consistent');
    if (updated.streak >= 30)  unlock('unwavering');
    if (updated.streak >= 100) unlock('the_relentless');
    if (updated.streak >= 365) unlock('ascendant');

    // ── Level milestones ──────────────────────────────────
    if (updated.level >= 10) unlock('level_10');
    if (updated.level >= 25) unlock('level_25');

    // ── Quests ────────────────────────────────────────────
    if (updated.questsCompleted >= 1)  unlock('quest_taker');
    if (updated.questsCompleted >= 50) unlock('grinder');

    // ── Combat ────────────────────────────────────────────
    if (updated.monstersKilled >= 1)  unlock('first_blood');
    if (updated.monstersKilled >= 10) unlock('monster_slayer');

    // ── Knowledge ─────────────────────────────────────────
    final knowledgeNames = const {
      'OWASP Top 10 Grimoire',
      'Nmap Codex',
      'Clean Code Scroll',
      'Linux PrivEsc Handbook',
      'Git Mastery Tome',
      'SQL Injection Grimoire',
    };
    final ownedKnowledge = updated.inventory.keys
        .where((k) => knowledgeNames.contains(k))
        .length;
    if (ownedKnowledge >= 1) unlock('scholar');
    if (ownedKnowledge >= 3) unlock('librarian');
    if (ownedKnowledge >= 6) unlock('living_encyclopedia');

    if (achievements.length != updated.achievements.length) {
      updated = updated.copyWith(achievements: achievements);
    }
    return updated;
  }

  /// Fires achievement notifications for [ids]. Call AFTER save succeeds.
  void _notifyAchievements(List<String> ids) {
    for (final id in ids) {
      final a = AchievementCatalog.get(id);
      if (a == null) continue;
      _createNotification(
        '"Achievement unlocked: ${a.name} — ${a.description}"',
        NotificationType.achievement,
      );
    }
  }
}
