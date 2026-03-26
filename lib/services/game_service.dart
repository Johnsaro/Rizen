import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_data.dart';
import '../models/quest.dart';
import '../models/game_notification.dart';
import '../models/achievement.dart';
import '../models/personal_record.dart';
import 'guest_session.dart';
import 'local_storage_service.dart';
import 'storage_router.dart';
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
    if (GuestSession.isActive) return GuestSession.userId;
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

      var result = await StorageRouter.loadProfile(_userId);

      debugPrint('[GameService] loadProfile result for $_userId: ${result != null ? "found" : "null"}');

      // Web-registered users have auth metadata (full_name, class) but no
      // profile row yet. Auto-create their profile so they skip GM onboarding.
      // Skip for guests — they get a default local profile, not a Supabase row.
      if (result == null && !GuestSession.isActive) {
        final meta =
            Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
        final webName = (meta['full_name'] as String?)?.trim() ?? '';
        final webClass = (meta['class'] as String?)?.trim() ?? '';

        debugPrint('[GameService] No onboarded profile — checking auth metadata: name="$webName" class="$webClass" allMeta=$meta');

        // Web signup already stores V2 path names — use directly
        final resolvedPath = webClass.isNotEmpty ? webClass : 'Formation Master';

        if (webName.isNotEmpty) {
          debugPrint('[GameService] Auto-creating profile: name="$webName" mainPath="$resolvedPath" (raw class="$webClass")');
          final webPlayer = PlayerData(
            name: webName,
            mainPath: resolvedPath,
            sidePath: 'Shadow Arts',
          );
          await SupabaseService.saveProfile(
            _userId,
            webPlayer,
            onboardingComplete: true,
            // Gemini Edit (2026-03-18): Added originPlatform to distinguish web/flutter users since Alex is unavailable
            originPlatform: 'browser',
          );
          // Re-load so the rest of loadAll sees the freshly created row
          result = await SupabaseService.loadProfile(_userId);
          debugPrint('[GameService] Re-loaded after auto-create: ${result != null ? "success" : "STILL NULL"}');
        } else {
          debugPrint('[GameService] Cannot auto-create — webName is empty. User needs Flutter onboarding.');
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
              int streak = player.daoHeartStreak;
              int talismans = player.talismans;

              // Consume talismans first, then break streak only if they ran out
              final consumed = talismans > missedDays ? missedDays : talismans;
              talismans -= consumed;
              if (missedDays > consumed) {
                streak = 0;
              }

              if (streak != player.daoHeartStreak || talismans != player.talismans) {
                var penalized = player.copyWith(
                  daoHeartStreak: streak,
                  talismans: talismans,
                  daoHeartState: PlayerData.stateForStreak(streak),
                );

                // Qi Deviation trigger — breaking a 14-29 day streak causes deviation
                // Immovable (30+) is immune; talisman-absorbed breaks don't trigger
                if (streak == 0 && player.daoHeartStreak >= 14 && player.daoHeartStreak < 30) {
                  final expiry = DateTime.now().add(const Duration(hours: 48)).toUtc().toIso8601String();
                  penalized = penalized.copyWith(
                    qiDeviationActive: true,
                    qiDeviationExpiry: expiry,
                    qiDeviationTrials: 0,
                  );
                }

                // Only commit penalty if Supabase write succeeds — prevents double-deduction on crash
                try {
                  await StorageRouter.saveProfile(_userId, penalized);
                  player = penalized;
                  if (streak == 0) {
                    _createNotification(
                      '"Your streak has broken. The foundation cracks. Begin again — stronger."',
                      NotificationType.streakBreak,
                    );
                    if (penalized.qiDeviationActive && penalized.qiDeviationExpiry.isNotEmpty) {
                      _createNotification(
                        '"Qi deviation detected. Your foundation shatters. Complete 3 trials within 48 hours to stabilize."',
                        NotificationType.qiDeviation,
                      );
                    }
                  } else if (consumed > 0) {
                    _createNotification(
                      '"Your talismans absorbed $consumed missed day${consumed > 1 ? 's' : ''}. Streak preserved."',
                      NotificationType.info,
                    );
                  }
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

        // Clean expired pills on load and persist if any were removed.
        // Always use cleaned state locally — even if DB save fails, expired
        // pills return false from isPillActive() so gameplay is unaffected.
        // The save is best-effort to keep DB in sync.
        final cleaned = player.cleanExpiredPills();
        if (!identical(cleaned, player)) {
          player = cleaned;
          try {
            await StorageRouter.saveProfile(_userId, player);
          } catch (e) {
            debugPrint('Failed to persist cleaned pills: $e');
          }
        }

        // Auto-clear expired Qi Deviation (48h timer elapsed)
        if (player.qiDeviationActive && !player.isQiDeviationActive) {
          player = player.clearQiDeviation();
          try {
            await StorageRouter.saveProfile(_userId, player);
          } catch (e) {
            debugPrint('Failed to persist cleared Qi Deviation: $e');
          }
        }

        playerNotifier.value = player;
      }

      // Weapon durability idle decay
      await applyDurabilityDecay();

      final quests = await StorageRouter.loadQuests(_userId);
      if (quests.isNotEmpty) {
        questNotifier.value = quests;
      } else {
        // New user — start with an empty board; quests come from the Guild Master
        questNotifier.value = [];
      }

      // Quest expiry check
      await _checkExpiredQuests(today);

      final guildBoard = await StorageRouter.loadGuildBoard(_userId, today);
      guildBoardNotifier.value = guildBoard;

      final notifications = await StorageRouter.loadNotifications(_userId);
      notificationsNotifier.value = notifications;

      final prs = await StorageRouter.loadPersonalRecords(_userId);
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

      final stoneGain = (quest.xpReward * 0.1).round();
      final updatedQuests = prevQuests
          .map((q) => q.id == quest.id ? q.copyWith(isCompleted: true) : q)
          .toList();
      var updatedPlayer = _awardQiAndStones(
        prevPlayer,
        quest.xpReward,
        stoneGain,
        classTag: quest.classTag,
        isQuestReward: true,
      );
      // Consume Qi Surge AFTER multiplier was applied but BEFORE save —
      // this way rollback to prevPlayer still has the surge intact.
      if (prevPlayer.isPillActive('Qi Surge Pill')) {
        final cleanedPills = Map<String, String>.from(updatedPlayer.activePills)
          ..remove('Qi Surge Pill');
        updatedPlayer = updatedPlayer.copyWith(activePills: cleanedPills);
      }
      updatedPlayer = updatedPlayer.copyWith(
        trialsCompleted: updatedPlayer.trialsCompleted + 1,
      );

      // Qi Deviation recovery — each quest completion counts as a trial
      if (updatedPlayer.isQiDeviationActive) {
        final newTrials = updatedPlayer.qiDeviationTrials + 1;
        if (newTrials >= 3) {
          updatedPlayer = updatedPlayer.clearQiDeviation();
        } else {
          updatedPlayer = updatedPlayer.copyWith(qiDeviationTrials: newTrials);
        }
      }

      final newAchievements = <String>[];
      updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);

      playerNotifier.value = updatedPlayer;
      questNotifier.value = updatedQuests;

      try {
        // Save quests first — if this fails, profile (with consumed surge) is never written
        await StorageRouter.saveQuests(_userId, updatedQuests);
        await StorageRouter.saveProfile(_userId, updatedPlayer);

        // Notifications — fire-and-forget, do not affect rollback
        _createNotification(
          '"Quest complete. ${quest.title} — ${quest.xpReward} XP claimed."',
          NotificationType.questComplete,
        );
        // Qi Deviation cleared notification
        if (!updatedPlayer.qiDeviationActive && prevPlayer.isQiDeviationActive) {
          _createNotification(
            '"Qi deviation stabilized. Your foundation is restored."',
            NotificationType.qiDeviation,
          );
        }
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
      await StorageRouter.saveQuests(_userId, updatedQuests);
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
      await StorageRouter.saveGuildBoard(_userId, updatedBoard, today);
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
    final newStreak = prevPlayer.daoHeartStreak + 1;

    // Milestone rewards — re-trigger on every rebuild (simpler, more motivating)
    int bonusStones = 0;
    int bonusTalismans = 0;
    if (newStreak == 7)   { bonusStones = 200;   bonusTalismans = 1; }
    if (newStreak == 30)  { bonusStones = 500; }
    if (newStreak == 60)  { bonusStones = 1000; }
    if (newStreak == 100) { bonusStones = 2000; }
    if (newStreak == 365) { bonusStones = 2000; }

    // Base check-in rewards: +50 Qi, +5 Spirit Stones (+ any milestone bonus)
    var updatedPlayer = _awardQiAndStones(prevPlayer, 50, 5 + bonusStones, classTag: 'Any');
    final newTalismans = (updatedPlayer.talismans + bonusTalismans).clamp(0, 3);
    final newState = PlayerData.stateForStreak(newStreak);
    final prevState = PlayerData.stateForStreak(prevPlayer.daoHeartStreak);
    updatedPlayer = updatedPlayer.copyWith(
      daoHeartStreak: newStreak,
      talismans: newTalismans,
      daoHeartState: newState,
    );
    final newAchievements = <String>[];
    updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);

    playerNotifier.value = updatedPlayer;
    checkedInNotifier.value = true;

    try {
      await StorageRouter.saveProfile(_userId, updatedPlayer, checkinDate: today);

      // Notifications — fire-and-forget
      _createNotification(
        '"You have arrived. The guild acknowledges your presence."',
        NotificationType.checkin,
      );
      // Dao Heart state transition notification
      if (newState != prevState) {
        _createNotification(
          _daoHeartTransitionMessage(newState),
          NotificationType.streakMilestone,
        );
      }
      if (bonusStones > 0) {
        _createNotification(
          '"$newStreak day streak. The guild recognizes your dedication. +$bonusStones Spirit Stones awarded."',
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

  // ── Merchant's Log Qi reward ─────────────────────────────

  /// Awards a small Qi reward for logging an expense in the Merchant's Log.
  /// Intentionally tiny (10 Qi, 0 stones) — encourages tracking without gaming.
  Future<void> awardMerchantLogQi() async {
    if (!_hasSession) return;
    final prev = playerNotifier.value;
    final updated = _awardQiAndStones(prev, 10, 0);
    playerNotifier.value = updated;
    try {
      await StorageRouter.saveProfile(_userId, updated);
    } catch (e) {
      playerNotifier.value = prev;
      errorNotifier.value = 'Failed to save Qi reward.';
    }
  }

  // ── Shop purchase ────────────────────────────────────────

  Future<void> purchaseItem(String itemName, int cost) async {
    if (!_hasSession) return;
    if (_purchasingItems.contains(itemName)) return;
    _purchasingItems.add(itemName);

    try {
      final prevPlayer = playerNotifier.value;
      var updatedPlayer = prevPlayer.buyItem(itemName, cost);
      final newAchievements = <String>[];
      updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);
      playerNotifier.value = updatedPlayer;

      try {
        await StorageRouter.saveProfile(_userId, updatedPlayer);
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
        case 'Vitality Pill':
          if (prevPlayer.maxHp <= 0) return 'Cannot use — max HP is invalid';
          if (prevPlayer.hp >= prevPlayer.maxHp) return 'HP is already full';
          final newHp = (prevPlayer.hp + 300).clamp(0, prevPlayer.maxHp);
          updatedPlayer = prevPlayer.useInstantItem(itemName).copyWith(hp: newHp);

        case 'Protective Talisman':
          if (prevPlayer.talismans >= 3) return 'Talismans already at max (3)';
          updatedPlayer = prevPlayer.useInstantItem(itemName)
              .copyWith(talismans: (prevPlayer.talismans + 1).clamp(0, 3));

        case 'Focus Elixir':
          if (prevPlayer.isPillActive('Focus Elixir')) return 'Focus Elixir is already active';
          updatedPlayer = prevPlayer.activatePill('Focus Elixir', itemName, const Duration(hours: 2));

        case 'Spirit Stone Tonic':
          if (prevPlayer.isPillActive('Spirit Stone Tonic')) return 'Spirit Stone Tonic is already active';
          updatedPlayer = prevPlayer.activatePill('Spirit Stone Tonic', itemName, const Duration(hours: 1));

        case 'Qi Surge Pill':
          if (prevPlayer.isPillActive('Qi Surge Pill')) return 'Qi Surge Pill is already active';
          updatedPlayer = prevPlayer.activateQiSurge();

        case 'Durability Kit':
        case 'Time Warp':
          return 'Coming soon — not yet implemented';

        default:
          return 'Unknown item';
      }

      playerNotifier.value = updatedPlayer;

      try {
        await StorageRouter.saveProfile(_userId, updatedPlayer);
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
    String? originPlatform,
  }) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;
    playerNotifier.value = updated;

    try {
      await StorageRouter.saveProfile(
        _userId,
        updated,
        checkinDate: checkinDate,
        onboardingComplete: onboardingComplete,
        originPlatform: originPlatform,
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
      await StorageRouter.saveProfile(_userId, updatedPlayer);
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
      await StorageRouter.saveProfile(_userId, updatedPlayer);
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

    var updatedPlayer = _awardQiAndStones(prevPlayer, xpReward, 0, classTag: classTag, isQuestReward: true);
    // Consume Qi Surge after multiplier applied — rollback to prevPlayer preserves it
    if (prevPlayer.isPillActive('Qi Surge Pill')) {
      final cleanedPills = Map<String, String>.from(updatedPlayer.activePills)
        ..remove('Qi Surge Pill');
      updatedPlayer = updatedPlayer.copyWith(activePills: cleanedPills);
    }
    updatedPlayer = updatedPlayer.copyWith(
      hp: updatedPlayer.maxHp,
      monstersKilled: updatedPlayer.monstersKilled + 1,
    );

    // Qi Deviation recovery — each combat victory counts as a trial
    if (updatedPlayer.isQiDeviationActive) {
      final newTrials = updatedPlayer.qiDeviationTrials + 1;
      if (newTrials >= 3) {
        updatedPlayer = updatedPlayer.clearQiDeviation();
      } else {
        updatedPlayer = updatedPlayer.copyWith(qiDeviationTrials: newTrials);
      }
    }

    final newAchievements = <String>[];
    updatedPlayer = _checkAndUnlockAchievements(updatedPlayer, newUnlocks: newAchievements);
    playerNotifier.value = updatedPlayer;

    try {
      await StorageRouter.saveProfile(_userId, updatedPlayer);
      if (xpReward > 0) {
        _createNotification(
          '"Monster defeated. +$xpReward XP claimed. HP restored."',
          NotificationType.combatVictory,
        );
      }
      // Qi Deviation cleared notification
      if (!updatedPlayer.qiDeviationActive && prevPlayer.isQiDeviationActive) {
        _createNotification(
          '"Qi deviation stabilized. Your foundation is restored."',
          NotificationType.qiDeviation,
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
    final newQi = (prevPlayer.qi - xpPenalty).clamp(0.0, prevPlayer.qi);
    final updatedPlayer = prevPlayer.copyWith(qi: newQi, hp: prevPlayer.maxHp);
    playerNotifier.value = updatedPlayer;

    try {
      await StorageRouter.saveProfile(_userId, updatedPlayer);
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

    final newQi = (prevPlayer.qi - xpLoss).clamp(0.0, prevPlayer.qi);
    final updatedPlayer = prevPlayer.copyWith(qi: newQi, hp: prevPlayer.maxHp);
    playerNotifier.value = updatedPlayer;

    try {
      await StorageRouter.saveProfile(_userId, updatedPlayer);
      _createNotification(
        '"You have been defeated. -$xpLoss XP lost. The guild awaits your return."',
        NotificationType.streakBreak,
      );
      // Apply durability loss to equipped weapons on death
      await applyWeaponDurabilityLoss(15);
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to save combat result. Try again.';
    }
  }

  // ── Weapon durability ───────────────────────────────────────

  /// Applies idle durability decay based on days since last use.
  /// Called once in loadAll(). Idempotent — uses weaponLastUsed dates.
  Future<void> applyDurabilityDecay() async {
    if (!_hasSession) return;
    final player = playerNotifier.value;
    if (player.weaponDurability.isEmpty) return;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final newDurability = Map<String, int>.from(player.weaponDurability);
    final newLastUsed = Map<String, String>.from(player.weaponLastUsed);
    bool changed = false;
    final equippedSet = player.equippedWeapons.toSet();

    for (final weapon in newDurability.keys.toList()) {
      final lastUsedStr = newLastUsed[weapon];
      if (lastUsedStr == null || lastUsedStr == todayStr) continue;

      final lastUsed = DateTime.tryParse(lastUsedStr);
      if (lastUsed == null) continue;

      final daysSince = today.difference(lastUsed).inDays;
      if (daysSince < 2) continue;

      final isEquipped = equippedSet.contains(weapon);
      // Equipped weapons decay at half rate
      final effectiveDays = isEquipped ? (daysSince / 2).ceil() : daysSince;

      int newDur = newDurability[weapon] ?? 100;
      if (effectiveDays >= 7) {
        newDur = 0;
      } else if (effectiveDays >= 6) {
        newDur = (newDur * 0.4).round().clamp(0, 100);
      } else if (effectiveDays >= 4) {
        newDur = (newDur * 0.7).round().clamp(0, 100);
      }
      // 2-3 days: warning only, no durability change

      if (newDur != newDurability[weapon]) {
        newDurability[weapon] = newDur;
        changed = true;
      }

      // Notify on any weapon at risk
      if (effectiveDays >= 2 && effectiveDays < 4) {
        _createNotification(
          '"Your $weapon is gathering dust. Use it or lose it."',
          NotificationType.info,
        );
      }
    }

    if (changed) {
      final updated = player.copyWith(weaponDurability: newDurability);
      playerNotifier.value = updated;
      try {
        await StorageRouter.saveProfile(_userId, updated);
      } catch (e) {
        debugPrint('Failed to persist durability decay: $e');
      }
    }
  }

  /// Repairs a weapon to full durability (100). Called after Flashcard Repair Mode.
  Future<void> repairWeapon(String weaponName) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;
    final newDurability = Map<String, int>.from(prevPlayer.weaponDurability);
    final newLastUsed = Map<String, String>.from(prevPlayer.weaponLastUsed);
    newDurability[weaponName] = 100;
    newLastUsed[weaponName] = DateTime.now().toIso8601String().substring(0, 10);

    final updated = prevPlayer.copyWith(
      weaponDurability: newDurability,
      weaponLastUsed: newLastUsed,
    );
    playerNotifier.value = updated;

    try {
      await StorageRouter.saveProfile(_userId, updated);
      _createNotification(
        '"$weaponName has been restored to full refinement."',
        NotificationType.info,
      );
    } catch (e) {
      playerNotifier.value = prevPlayer;
      errorNotifier.value = 'Failed to repair weapon. Try again.';
    }
  }

  /// Deducts durability from equipped weapons on combat death.
  Future<void> applyWeaponDurabilityLoss(int amount) async {
    if (!_hasSession) return;
    final prevPlayer = playerNotifier.value;
    if (prevPlayer.equippedWeapons.isEmpty) return;

    final newDurability = Map<String, int>.from(prevPlayer.weaponDurability);
    for (final weapon in prevPlayer.equippedWeapons) {
      final current = newDurability[weapon] ?? 100;
      newDurability[weapon] = (current - amount).clamp(0, 100);
    }

    final updated = prevPlayer.copyWith(weaponDurability: newDurability);
    playerNotifier.value = updated;

    try {
      await StorageRouter.saveProfile(_userId, updated);
    } catch (e) {
      playerNotifier.value = prevPlayer;
      debugPrint('Failed to persist durability loss: $e');
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
      await StorageRouter.saveQuests(_userId, updatedQuests);
      await StorageRouter.saveProfile(_userId, updatedPlayer);
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
    final newQi = (player.qi * 0.6).floorToDouble();
    final bottomed = player.level == 1 && newQi == 0;
    return player.copyWith(
      qi: newQi,
      title: bottomed ? 'Lazy Sloth Slave' : player.title,
    );
  }

  // ── Clear notifications ──────────────────────────────────

  Future<void> clearNotifications() async {
    if (!_hasSession) return;
    final prev = notificationsNotifier.value;
    notificationsNotifier.value = [];
    try {
      await StorageRouter.clearNotifications(_userId);
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
      final record = await StorageRouter.addPersonalRecord(
        _userId,
        title: title,
        category: category,
        description: description,
        mood: mood,
        metricType: metricType,
        metricValue: metricValue,
        tags: tags,
        streakContext: playerNotifier.value.daoHeartStreak,
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

  // ── Guest-to-account migration ──────────────────────────

  /// Transfers all local guest data to Supabase under the newly authenticated
  /// userId, then clears the guest session. Call AFTER successful sign-up.
  Future<bool> migrateGuestToAccount() async {
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (authId.isEmpty) return false;

    try {
      final guestId = GuestSession.userId;

      // Read all local data
      final profile = await LocalStorageService.loadProfile(guestId);
      final quests = await LocalStorageService.loadQuests(guestId);
      final guildBoard = await LocalStorageService.loadGuildBoard(
        guestId,
        DateTime.now().toIso8601String().substring(0, 10),
      );
      final notifications = await LocalStorageService.loadNotifications(guestId);
      final prs = await LocalStorageService.loadPersonalRecords(guestId);

      // Write to Supabase under the real auth ID
      if (profile != null) {
        await SupabaseService.saveProfile(
          authId,
          profile.player,
          checkinDate: profile.checkedInDate.isNotEmpty ? profile.checkedInDate : null,
          onboardingComplete: true,
          originPlatform: 'flutter',
        );
      }
      if (quests.isNotEmpty) {
        await SupabaseService.saveQuests(authId, quests);
      }
      if (guildBoard.isNotEmpty) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await SupabaseService.saveGuildBoard(authId, guildBoard, today);
      }
      for (final notif in notifications) {
        await SupabaseService.addNotification(authId, notif.message, notif.type);
      }
      for (final pr in prs) {
        await SupabaseService.addPersonalRecord(
          authId,
          title: pr.title,
          category: pr.category.value,
          description: pr.description,
          mood: pr.mood,
          metricType: pr.metricType,
          metricValue: pr.metricValue,
          tags: pr.tags,
          streakContext: pr.streakContext,
        );
      }

      // Clear guest state
      await GuestSession.clear();

      // Reload everything from Supabase
      await loadAll();

      return true;
    } catch (e) {
      debugPrint('Guest migration failed: $e');
      errorNotifier.value = 'Migration failed. Your local data is still safe.';
      return false;
    }
  }

  // ── Private helpers ──────────────────────────────────────

  /// Centralises Qi + Spirit Stone arithmetic so all reward paths use the same logic.
  /// Applies active pill multipliers (Focus Elixir, Qi Surge Pill, Spirit Stone Tonic).
  /// Set [isQuestReward] to true when called from quest completion or combat
  /// victory — only those paths apply the Qi Surge multiplier.
  ///
  /// NOTE: This method no longer removes Qi Surge from activePills. Callers
  /// that consume surge must remove it themselves BEFORE the Supabase save,
  /// so that a failed save + rollback preserves the pill correctly.
  PlayerData _awardQiAndStones(
    PlayerData player,
    int qi,
    int stones, {
    String classTag = 'Any',
    bool isQuestReward = false,
  }) {
    double qiMultiplier = 1.0;
    double stoneMultiplier = 1.0;

    if (player.isPillActive('Focus Elixir')) {
      qiMultiplier += 0.5;
    }
    if (player.isPillActive('Qi Surge Pill') && isQuestReward) {
      qiMultiplier += 1.0;
    }
    if (player.isPillActive('Spirit Stone Tonic')) {
      stoneMultiplier += 1.0;
    }

    // Dao Heart state bonus (+5% to +20%)
    qiMultiplier += PlayerData.qiBonusForStreak(player.daoHeartStreak);

    // Qi Deviation penalty — halves total Qi gain
    if (player.isQiDeviationActive) {
      qiMultiplier *= 0.5;
    }

    final effectiveQi = (qi * qiMultiplier).round();
    final effectiveStones = (stones * stoneMultiplier).round();

    return player
        .addQi(effectiveQi, pathTag: classTag)
        .addSpiritStones(effectiveStones);
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

    StorageRouter.addNotification(_userId, message, type).catchError((_) {
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
      if (a.spiritStoneReward > 0) {
        updated = updated.copyWith(achievements: achievements).addSpiritStones(a.spiritStoneReward);
      }
      if (a.titleReward != null) {
        updated = updated.copyWith(title: a.titleReward, achievements: achievements);
      }
    }

    // ── Consistency (streak) ──────────────────────────────
    if (updated.daoHeartStreak >= 1)   unlock('first_step');
    if (updated.daoHeartStreak >= 7)   unlock('the_consistent');
    if (updated.daoHeartStreak >= 30)  unlock('unwavering');
    if (updated.daoHeartStreak >= 100) unlock('the_relentless');
    if (updated.daoHeartStreak >= 365) unlock('ascendant');

    // ── Level milestones ──────────────────────────────────
    if (updated.level >= 10) unlock('level_10');
    if (updated.level >= 25) unlock('level_25');

    // ── Quests ────────────────────────────────────────────
    if (updated.trialsCompleted >= 1)  unlock('quest_taker');
    if (updated.trialsCompleted >= 50) unlock('grinder');

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

  /// Narrative message for Dao Heart state transitions.
  String _daoHeartTransitionMessage(String state) => switch (state) {
    'Steady'     => '"Your Dao Heart steadies. +5% Qi."',
    'Firm'       => '"Your Dao Heart grows firm. Lesser demons dare not approach. +10% Qi."',
    'Unyielding' => '"Your Dao Heart is unyielding. +15% Qi."',
    'Immovable'  => '"Your Dao Heart is immovable. Immune to minor Qi Deviation. +20% Qi."',
    _            => '"Your Dao Heart flickers."',
  };
}
