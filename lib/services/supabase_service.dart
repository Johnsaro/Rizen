import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config.dart';
import '../models/player_data.dart';
import '../models/quest.dart';
import '../models/game_notification.dart';
import '../models/personal_record.dart';

// Record type returned by loadProfile — carries both the player data and the
// checked-in date stored in the profile row.
typedef ProfileResult = ({PlayerData player, String checkedInDate});

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Max wait time for any single Supabase operation before giving up.
  static const _timeout = Duration(seconds: 15);

  // ── App Config ────────────────────────────────────────

  /// Loads remote app config (maintenance mode, version gates).
  /// Returns [AppConfig.fallback] on any error so the app never blocks
  /// users just because the config table is unreachable.
  static Future<AppConfig> loadAppConfig() async {
    try {
      final row = await _client
          .from('app_config')
          .select()
          .eq('id', 1)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) return AppConfig.fallback;
      return AppConfig.fromRow(row);
    } catch (e) {
      debugPrint('SupabaseService.loadAppConfig failed: $e');
      return AppConfig.fallback;
    }
  }

  // ── Profile ────────────────────────────────────────────

  /// Loads the player profile for [userId].
  /// Returns null if no completed-onboarding profile exists yet.
  static Future<ProfileResult?> loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .eq('onboarding_complete', true)
        .maybeSingle()
        .timeout(_timeout);

    if (row == null) return null;

    final player = PlayerData(
      name: (row['name'] as String?) ?? '',
      mainClass: (row['main_class'] as String?) ?? 'Web Developer',
      sideClass: (row['side_class'] as String?) ?? 'Sec Analyst',
      level: (row['level'] as num?)?.toInt() ?? 1,
      currentXP: (row['current_xp'] as num?)?.toDouble() ?? 0.0,
      rep: (row['rep'] as num?)?.toInt() ?? 0,
      classXp: _toDoubleMap(row['class_xp']),
      classLevel: _toIntMap(row['class_level']),
      inventory: _toIntMap(row['inventory']),
      streak: (row['streak'] as num?)?.toInt() ?? 0,
      shields: (row['shields'] as num?)?.toInt() ?? 0,
      title: (row['title'] as String?) ?? '',
      hp: (row['hp'] as num?)?.toInt() ?? 100,
      maxHp: (row['max_hp'] as num?)?.toInt() ?? 100,
      equippedWeapon: (row['equipped_weapon'] as String?) ?? '',
      activeBuffs: _toStringMap(row['active_buffs']),
      achievements: _toStringMap(row['achievements']),
      featuredAchievement: (row['featured_achievement'] as String?) ?? '',
      questsCompleted: (row['quests_completed'] as num?)?.toInt() ?? 0,
      monstersKilled: (row['monsters_killed'] as num?)?.toInt() ?? 0,
      equippedCosmetics: _toStringMap(row['equipped_cosmetics']),
    );

    return (
      player: player,
      checkedInDate: (row['checked_in_date'] as String?) ?? '',
    );
  }

  /// Upserts the player profile. Pass [checkinDate] to also update
  /// the checked-in date. Pass [onboardingComplete] when finalising onboarding.
  static Future<void> saveProfile(
    String userId,
    PlayerData p, {
    String? checkinDate,
    bool? onboardingComplete,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'name': p.name,
      'main_class': p.mainClass,
      'side_class': p.sideClass,
      'level': p.level,
      'current_xp': p.currentXP,
      'rep': p.rep,
      'class_xp': p.classXp,
      'class_level': p.classLevel,
      'inventory': p.inventory,
      'streak': p.streak,
      'shields': p.shields,
      'title': p.title,
      'hp': p.hp,
      'max_hp': p.maxHp,
      'equipped_weapon': p.equippedWeapon,
      'active_buffs': p.activeBuffs,
      'achievements': p.achievements,
      'featured_achievement': p.featuredAchievement,
      'quests_completed': p.questsCompleted,
      'monsters_killed': p.monstersKilled,
      'equipped_cosmetics': p.equippedCosmetics,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'checked_in_date': ?checkinDate,
      'onboarding_complete': ?onboardingComplete,
    };

    await _client
        .from('profiles')
        .upsert(data, onConflict: 'user_id')
        .timeout(_timeout);
  }

  /// Sets onboarding_complete = true for [userId].
  static Future<void> markOnboardingComplete(String userId) async {
    await _client
        .from('profiles')
        .update({'onboarding_complete': true})
        .eq('user_id', userId)
        .timeout(_timeout);
  }

  // ── Quests ─────────────────────────────────────────────

  /// Loads all quests for [userId].
  static Future<List<Quest>> loadQuests(String userId) async {
    final rows = await _client
        .from('quests')
        .select()
        .eq('user_id', userId)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => _questFromRow(e as Map<String, dynamic>))
        .toList();
  }

  /// Upserts all [quests] for [userId] in a single call.
  /// When [quests] is empty, explicitly deletes all rows so expired quests
  /// don't survive in the DB and re-trigger penalties on the next launch.
  static Future<void> saveQuests(String userId, List<Quest> quests) async {
    if (quests.isEmpty) {
      await _client.from('quests').delete().eq('user_id', userId).timeout(_timeout);
      return;
    }
    final rows = quests
        .map((q) => {
              'id': q.id,
              'user_id': userId,
              'title': q.title,
              'description': q.description,
              'rank': q.rank,
              'type': q.type,
              'xp_reward': q.xpReward,
              'class_tag': q.classTag,
              'is_completed': q.isCompleted,
              'deadline': q.deadline,
            })
        .toList();
    await _client.from('quests').upsert(rows, onConflict: 'id').timeout(_timeout);
  }

  // ── Guild board ────────────────────────────────────────

  /// Loads the guild board quests for [userId] on [date] (YYYY-MM-DD).
  static Future<List<Quest>> loadGuildBoard(
      String userId, String date) async {
    final rows = await _client
        .from('guild_board')
        .select()
        .eq('user_id', userId)
        .eq('board_date', date)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => _questFromGuildBoardRow(e as Map<String, dynamic>))
        .toList();
  }

  /// Upserts [quests] onto the guild board for [userId] on [date].
  static Future<void> saveGuildBoard(
      String userId, List<Quest> quests, String date) async {
    if (quests.isEmpty) return;
    final rows = quests
        .map((q) => {
              'id': q.id,
              'user_id': userId,
              'title': q.title,
              'description': q.description,
              'rank': q.rank,
              'type': q.type,
              'xp_reward': q.xpReward,
              'class_tag': q.classTag,
              'board_date': date,
            })
        .toList();
    await _client.from('guild_board').upsert(rows, onConflict: 'id').timeout(_timeout);
  }

  // ── Notifications ──────────────────────────────────────

  /// Loads the 50 most recent notifications for [userId].
  static Future<List<GameNotification>> loadNotifications(String userId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => GameNotification.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a single notification row for [userId].
  static Future<void> addNotification(
    String userId,
    String message,
    NotificationType type,
  ) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'message': message,
      'type': type.value,
    }).timeout(_timeout);
  }

  /// Deletes all notifications for [userId].
  static Future<void> clearNotifications(String userId) async {
    await _client.from('notifications').delete().eq('user_id', userId).timeout(_timeout);
  }

  // ── Personal Records ────────────────────────────────────

  /// Loads all personal records for [userId], newest first.
  static Future<List<PersonalRecord>> loadPersonalRecords(String userId) async {
    final rows = await _client
        .from('personal_records')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => PersonalRecord.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a personal record and returns the server-generated row.
  static Future<PersonalRecord> addPersonalRecord(
    String userId, {
    required String title,
    required String category,
    String description = '',
    String mood = '',
    String? metricType,
    String? metricValue,
    List<String> tags = const [],
    int? streakContext,
  }) async {
    final row = await _client
        .from('personal_records')
        .insert({
          'user_id': userId,
          'title': title,
          'category': category,
          'description': description,
          'mood': mood,
          'metric_type': metricType,
          'metric_value': metricValue,
          'tags': tags,
          'streak_context': streakContext,
        })
        .select()
        .single()
        .timeout(_timeout);

    return PersonalRecord.fromRow(row);
  }

  // ── Private helpers ────────────────────────────────────

  static Map<String, double> _toDoubleMap(dynamic data) {
    if (data == null) return {};
    return (data as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  static Map<String, int> _toIntMap(dynamic data) {
    if (data == null) return {};
    return (data as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Map<String, String> _toStringMap(dynamic data) {
    if (data == null || data is! Map) return {};
    return (data as Map<String, dynamic>).entries.fold<Map<String, String>>(
      {},
      (map, e) {
        if (e.value is String && (e.value as String).isNotEmpty) {
          map[e.key] = e.value as String;
        }
        return map;
      },
    );
  }

  static Quest _questFromRow(Map<String, dynamic> row) {
    return Quest(
      id: row['id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      rank: (row['rank'] as String?) ?? 'F',
      type: (row['type'] as String?) ?? 'daily',
      xpReward: (row['xp_reward'] as num).toInt(),
      classTag: (row['class_tag'] as String?) ?? 'Any',
      isCompleted: (row['is_completed'] as bool?) ?? false,
      deadline: (row['deadline'] as String?) ?? '',
    );
  }

  static Quest _questFromGuildBoardRow(Map<String, dynamic> row) {
    return Quest(
      id: row['id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      rank: (row['rank'] as String?) ?? 'F',
      type: (row['type'] as String?) ?? 'daily',
      xpReward: (row['xp_reward'] as num).toInt(),
      classTag: (row['class_tag'] as String?) ?? 'Any',
    );
  }
}
