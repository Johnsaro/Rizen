import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_data.dart';
import '../models/quest.dart';
import '../models/game_notification.dart';
import '../models/personal_record.dart';
import 'supabase_service.dart'; // for ProfileResult typedef

/// Local SharedPreferences-based storage that mirrors the SupabaseService
/// methods used by GameService. Used when GuestSession is active.
class LocalStorageService {
  static const _profileKey = 'guest_profile';
  static const _questsKey = 'guest_quests';
  static const _guildBoardKey = 'guest_guild_board';
  static const _notificationsKey = 'guest_notifications';
  static const _personalRecordsKey = 'guest_personal_records';

  static const _maxNotifications = 50;
  static const _maxRecords = 100;

  // ── Profile ────────────────────────────────────────────

  static Future<ProfileResult?> loadProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final player = _playerFromJson(data);
    final checkedInDate = (data['checked_in_date'] as String?) ?? '';
    return (player: player, checkedInDate: checkedInDate);
  }

  static Future<void> saveProfile(
    String userId,
    PlayerData p, {
    String? checkinDate,
    bool? onboardingComplete,
    String? originPlatform,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = _playerToJson(p);
    if (checkinDate != null) data['checked_in_date'] = checkinDate;
    if (onboardingComplete != null) data['onboarding_complete'] = onboardingComplete;
    if (originPlatform != null) data['origin_platform'] = originPlatform;
    await prefs.setString(_profileKey, jsonEncode(data));
  }

  // ── Quests ─────────────────────────────────────────────

  static Future<List<Quest>> loadQuests(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_questsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Quest.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveQuests(String userId, List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final data = quests.map((q) => q.toJson()).toList();
    await prefs.setString(_questsKey, jsonEncode(data));
  }

  // ── Guild Board ────────────────────────────────────────

  static Future<List<Quest>> loadGuildBoard(String userId, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guildBoardKey);
    if (raw == null) return [];
    final wrapper = jsonDecode(raw) as Map<String, dynamic>;
    // Only return board for the requested date
    if (wrapper['date'] != date) return [];
    final list = wrapper['quests'] as List<dynamic>;
    return list.map((e) => Quest.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveGuildBoard(
    String userId,
    List<Quest> quests,
    String date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final wrapper = {
      'date': date,
      'quests': quests.map((q) => q.toJson()).toList(),
    };
    await prefs.setString(_guildBoardKey, jsonEncode(wrapper));
  }

  // ── Notifications ──────────────────────────────────────

  static Future<List<GameNotification>> loadNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _notificationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addNotification(
    String userId,
    String message,
    NotificationType type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadNotifications(userId);
    final notif = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'message': message,
      'type': type.value,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    final updated = [notif, ...existing.map(_notificationToJson)];
    // Cap at max
    final capped = updated.length > _maxNotifications
        ? updated.sublist(0, _maxNotifications)
        : updated;
    await prefs.setString(_notificationsKey, jsonEncode(capped));
  }

  static Future<void> clearNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  // ── Personal Records ───────────────────────────────────

  static Future<List<PersonalRecord>> loadPersonalRecords(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personalRecordsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
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
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().toIso8601String();
    final id = 'pr_${DateTime.now().microsecondsSinceEpoch}';

    final row = <String, dynamic>{
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'mood': mood,
      'metric_type': metricType,
      'metric_value': metricValue,
      'tags': tags,
      'streak_context': streakContext,
      'created_at': now,
    };

    final existing = await loadPersonalRecords(userId);
    final allRows = [row, ...existing.map(_prToJson)];
    final capped = allRows.length > _maxRecords
        ? allRows.sublist(0, _maxRecords)
        : allRows;
    await prefs.setString(_personalRecordsKey, jsonEncode(capped));

    return PersonalRecord.fromRow(row);
  }

  // ── Serialization helpers ──────────────────────────────

  static Map<String, dynamic> _playerToJson(PlayerData p) => {
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
      };

  static PlayerData _playerFromJson(Map<String, dynamic> row) => PlayerData(
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
      );

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

  static GameNotification _notificationFromJson(Map<String, dynamic> row) {
    return GameNotification(
      id: row['id'] as String,
      message: row['message'] as String,
      type: NotificationType.fromString(row['type'] as String? ?? 'info'),
      isRead: (row['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  static Map<String, dynamic> _notificationToJson(GameNotification n) => {
        'id': n.id,
        'message': n.message,
        'type': n.type.value,
        'is_read': n.isRead,
        'created_at': n.createdAt.toUtc().toIso8601String(),
      };

  static Map<String, dynamic> _prToJson(PersonalRecord pr) => {
        'id': pr.id,
        'title': pr.title,
        'category': pr.category.value,
        'description': pr.description,
        'mood': pr.mood,
        'metric_type': pr.metricType,
        'metric_value': pr.metricValue,
        'tags': pr.tags,
        'streak_context': pr.streakContext,
        'created_at': pr.createdAt.toUtc().toIso8601String(),
      };
}
