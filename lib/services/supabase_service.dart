import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config.dart';
import '../models/player_data.dart';
import '../models/quest.dart';
import '../models/game_notification.dart';
import '../models/personal_record.dart';
import '../models/sect_path.dart';
import '../models/player_path.dart';
import '../models/lesson.dart';
import '../models/weapon.dart';

// Record type returned by loadProfile — carries the player data, the
// checked-in date, and whether onboarding was already completed.
typedef ProfileResult = ({PlayerData player, String checkedInDate, bool onboardingComplete});

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Max wait time for any single Supabase operation before giving up.
  static const _timeout = Duration(seconds: 15);

  // ── App Config ────────────────────────────────────────

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

  static Future<ProfileResult?> loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(_timeout);

    if (row == null) {
      debugPrint('[SupabaseService] loadProfile($userId): NO ROW AT ALL');
      return null;
    }

    final onboarded = (row['onboarding_complete'] as bool?) ?? false;
    debugPrint('[SupabaseService] loadProfile($userId): found row | onboarding_complete=$onboarded | name=${row['name']}');

    final player = PlayerData(
      name: (row['name'] as String?) ?? '',
      mainPath: (row['main_path'] as String?) ?? 'Shadow Arts',
      sidePath: (row['side_path'] as String?) ?? 'Shadow Arts',
      sect: (row['sect'] as String?) ?? '',
      activePath: (row['active_path'] as String?) ?? '',
      level: (row['level'] as num?)?.toInt() ?? 1,
      qi: (row['qi'] as num?)?.toDouble() ?? 0.0,
      spiritStones: (row['spirit_stones'] as num?)?.toInt() ?? 0,
      pathQi: _toDoubleMap(row['path_qi']),
      pathLevel: _toIntMap(row['path_level']),
      inventory: _toIntMap(row['inventory']),
      daoHeartStreak: (row['dao_heart_streak'] as num?)?.toInt() ?? 0,
      talismans: (row['talismans'] as num?)?.toInt() ?? 0,
      title: (row['title'] as String?) ?? '',
      hp: (row['hp'] as num?)?.toInt() ?? 100,
      maxHp: (row['max_hp'] as num?)?.toInt() ?? 100,
      equippedWeapon: (row['equipped_weapon'] as String?) ?? '',
      activePills: _toStringMap(row['active_pills']),
      achievements: _toStringMap(row['achievements']),
      featuredAchievement: (row['featured_achievement'] as String?) ?? '',
      trialsCompleted: (row['trials_completed'] as num?)?.toInt() ?? 0,
      monstersKilled: (row['monsters_killed'] as num?)?.toInt() ?? 0,
      equippedCosmetics: _toStringMap(row['equipped_cosmetics']),
      weaponDurability: _toIntMap(row['weapon_durability']),
      weaponLastUsed: _toStringMap(row['weapon_last_used']),
      equippedWeapons: (row['equipped_weapons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      realm: (row['realm'] as String?) ?? 'Mortal',
      realmRank: (row['realm_rank'] as num?)?.toInt() ?? 1,
      daoHeartState: (row['dao_heart_state'] as String?) ?? 'Wavering',
      qiDeviationActive: (row['qi_deviation_active'] as bool?) ?? false,
      qiDeviationExpiry: (row['qi_deviation_expiry'] as String?) ?? '',
      qiDeviationTrials: (row['qi_deviation_trials'] as num?)?.toInt() ?? 0,
    );

    return (
      player: player,
      checkedInDate: (row['checked_in_date'] as String?) ?? '',
      onboardingComplete: onboarded,
    );
  }

  static Future<void> saveProfile(
    String userId,
    PlayerData p, {
    String? checkinDate,
    bool? onboardingComplete,
    String? originPlatform,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'name': p.name,
      'main_path': p.mainPath,
      'side_path': p.sidePath,
      'sect': p.sect,
      'active_path': p.activePath,
      'level': p.level,
      'qi': p.qi,
      'spirit_stones': p.spiritStones,
      'path_qi': p.pathQi,
      'path_level': p.pathLevel,
      'inventory': p.inventory,
      'dao_heart_streak': p.daoHeartStreak,
      'talismans': p.talismans,
      'title': p.title,
      'hp': p.hp,
      'max_hp': p.maxHp,
      'equipped_weapon': p.equippedWeapon,
      'active_pills': p.activePills,
      'achievements': p.achievements,
      'featured_achievement': p.featuredAchievement,
      'trials_completed': p.trialsCompleted,
      'monsters_killed': p.monstersKilled,
      'equipped_cosmetics': p.equippedCosmetics,
      'weapon_durability': p.weaponDurability,
      'weapon_last_used': p.weaponLastUsed,
      'equipped_weapons': p.equippedWeapons,
      'realm': p.realm,
      'realm_rank': p.realmRank,
      'dao_heart_state': p.daoHeartState,
      'qi_deviation_active': p.qiDeviationActive,
      'qi_deviation_expiry': p.qiDeviationExpiry,
      'qi_deviation_trials': p.qiDeviationTrials,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (checkinDate != null) data['checked_in_date'] = checkinDate;
    if (onboardingComplete != null) data['onboarding_complete'] = onboardingComplete;
    if (originPlatform != null) data['origin_platform'] = originPlatform;

    try {
      await _client
          .from('profiles')
          .upsert(data, onConflict: 'user_id')
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[SupabaseService.saveProfile] DB ERROR: $e');
      debugPrint('[SupabaseService.saveProfile] Data keys: ${data.keys.toList()}');
      rethrow;
    }
  }

  static Future<void> markOnboardingComplete(String userId) async {
    await _client
        .from('profiles')
        .update({'onboarding_complete': true})
        .eq('user_id', userId)
        .timeout(_timeout);
  }

  // ── Quests ─────────────────────────────────────────────

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

  static Future<void> clearNotifications(String userId) async {
    await _client.from('notifications').delete().eq('user_id', userId).timeout(_timeout);
  }

  // ── Personal Records ────────────────────────────────────

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

  // ── Sect Paths ────────────────────────────────────────

  static Future<List<SectPath>> loadSectPaths(String sect) async {
    final rows = await _client
        .from('sect_paths')
        .select()
        .eq('sect', sect)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => SectPath.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SectPath>> loadAllSectPaths() async {
    final rows = await _client
        .from('sect_paths')
        .select()
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => SectPath.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  // ── Player Paths ─────────────────────────────────────

  static Future<List<PlayerPath>> loadPlayerPaths(String userId) async {
    final rows = await _client
        .from('player_paths')
        .select()
        .eq('user_id', userId)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => PlayerPath.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  static Future<PlayerPath> createPlayerPath(
    String userId,
    String pathId, {
    String rank = 'F',
  }) async {
    final row = await _client
        .from('player_paths')
        .insert({
          'user_id': userId,
          'path_id': pathId,
          'rank': rank,
          'xp': 0,
          'studied_topics': <String>[],
          'accuracy_stats': <String, dynamic>{},
        })
        .select()
        .single()
        .timeout(_timeout);

    return PlayerPath.fromRow(row);
  }

  static Future<void> savePlayerPath(PlayerPath pp) async {
    await _client
        .from('player_paths')
        .update({
          'rank': pp.rank,
          'xp': pp.xp,
          'studied_topics': pp.studiedTopics,
          'accuracy_stats': pp.accuracyStats,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', pp.id)
        .timeout(_timeout);
  }

  // ── Lesson Cache ────────────────────────────────────

  static Future<Lesson?> loadCachedLesson({
    required String pathId,
    required String topic,
    required String rank,
  }) async {
    final row = await _client
        .from('lesson_cache')
        .select()
        .eq('path_id', pathId)
        .eq('topic', topic)
        .eq('rank', rank)
        .maybeSingle()
        .timeout(_timeout);

    if (row == null) return null;
    return Lesson.fromRow(row);
  }

  static Future<Lesson> saveCachedLesson({
    required String pathId,
    required String topic,
    required String rank,
    required String lessonContent,
    required List<LessonQuiz> quizQuestions,
  }) async {
    final row = await _client
        .from('lesson_cache')
        .upsert({
          'path_id': pathId,
          'topic': topic,
          'rank': rank,
          'lesson_content': lessonContent,
          'quiz_questions':
              quizQuestions.map((q) => q.toJson()).toList(),
        }, onConflict: 'path_id,topic,rank')
        .select()
        .single()
        .timeout(_timeout);

    return Lesson.fromRow(row);
  }

  // ── Weapons (Catalog) ────────────────────────────────

  static Future<List<Weapon>> loadWeaponsForPath(String pathTag) async {
    final rows = await _client
        .from('weapons')
        .select()
        .eq('path_tag', pathTag)
        .order('cost')
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => Weapon.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Weapon>> loadWeaponsForSect(String sect) async {
    final rows = await _client
        .from('weapons')
        .select()
        .eq('sect', sect)
        .order('path_tag')
        .order('cost')
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => Weapon.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  // ── Player Weapons (Owned) ───────────────────────────

  static Future<List<PlayerWeapon>> loadPlayerWeapons(String userId) async {
    final rows = await _client
        .from('player_weapons')
        .select('*, weapons(*)')
        .eq('user_id', userId)
        .timeout(_timeout);

    return (rows as List<dynamic>)
        .map((e) => PlayerWeapon.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  static Future<PlayerWeapon> grantWeapon(
    String userId,
    String weaponId, {
    bool equip = false,
  }) async {
    final row = await _client
        .from('player_weapons')
        .upsert({
          'user_id': userId,
          'weapon_id': weaponId,
          'durability': 100,
          'is_equipped': equip,
        }, onConflict: 'user_id,weapon_id')
        .select('*, weapons(*)')
        .single()
        .timeout(_timeout);

    return PlayerWeapon.fromRow(row);
  }

  static Future<void> updatePlayerWeapon(PlayerWeapon pw) async {
    await _client
        .from('player_weapons')
        .update({
          'durability': pw.durability,
          'is_equipped': pw.isEquipped,
        })
        .eq('id', pw.id)
        .timeout(_timeout);
  }

  static Future<void> unequipAllWeapons(String userId) async {
    await _client
        .from('player_weapons')
        .update({'is_equipped': false})
        .eq('user_id', userId)
        .eq('is_equipped', true)
        .timeout(_timeout);
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
