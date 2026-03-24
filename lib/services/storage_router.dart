import '../models/player_data.dart';
import '../models/quest.dart';
import '../models/game_notification.dart';
import '../models/personal_record.dart';
import 'guest_session.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

/// Routes persistence calls to either SupabaseService or LocalStorageService
/// based on whether a guest session is active. Drop-in replacement for
/// direct SupabaseService calls in GameService.
class StorageRouter {
  // ── Profile ────────────────────────────────────────────

  static Future<ProfileResult?> loadProfile(String userId) {
    return GuestSession.isActive
        ? LocalStorageService.loadProfile(userId)
        : SupabaseService.loadProfile(userId);
  }

  static Future<void> saveProfile(
    String userId,
    PlayerData p, {
    String? checkinDate,
    bool? onboardingComplete,
    String? originPlatform,
  }) {
    return GuestSession.isActive
        ? LocalStorageService.saveProfile(userId, p,
            checkinDate: checkinDate,
            onboardingComplete: onboardingComplete,
            originPlatform: originPlatform)
        : SupabaseService.saveProfile(userId, p,
            checkinDate: checkinDate,
            onboardingComplete: onboardingComplete,
            originPlatform: originPlatform);
  }

  // ── Quests ─────────────────────────────────────────────

  static Future<List<Quest>> loadQuests(String userId) {
    return GuestSession.isActive
        ? LocalStorageService.loadQuests(userId)
        : SupabaseService.loadQuests(userId);
  }

  static Future<void> saveQuests(String userId, List<Quest> quests) {
    return GuestSession.isActive
        ? LocalStorageService.saveQuests(userId, quests)
        : SupabaseService.saveQuests(userId, quests);
  }

  // ── Guild Board ────────────────────────────────────────

  static Future<List<Quest>> loadGuildBoard(String userId, String date) {
    return GuestSession.isActive
        ? LocalStorageService.loadGuildBoard(userId, date)
        : SupabaseService.loadGuildBoard(userId, date);
  }

  static Future<void> saveGuildBoard(
    String userId,
    List<Quest> quests,
    String date,
  ) {
    return GuestSession.isActive
        ? LocalStorageService.saveGuildBoard(userId, quests, date)
        : SupabaseService.saveGuildBoard(userId, quests, date);
  }

  // ── Notifications ──────────────────────────────────────

  static Future<List<GameNotification>> loadNotifications(String userId) {
    return GuestSession.isActive
        ? LocalStorageService.loadNotifications(userId)
        : SupabaseService.loadNotifications(userId);
  }

  static Future<void> addNotification(
    String userId,
    String message,
    NotificationType type,
  ) {
    return GuestSession.isActive
        ? LocalStorageService.addNotification(userId, message, type)
        : SupabaseService.addNotification(userId, message, type);
  }

  static Future<void> clearNotifications(String userId) {
    return GuestSession.isActive
        ? LocalStorageService.clearNotifications(userId)
        : SupabaseService.clearNotifications(userId);
  }

  // ── Personal Records ───────────────────────────────────

  static Future<List<PersonalRecord>> loadPersonalRecords(String userId) {
    return GuestSession.isActive
        ? LocalStorageService.loadPersonalRecords(userId)
        : SupabaseService.loadPersonalRecords(userId);
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
  }) {
    return GuestSession.isActive
        ? LocalStorageService.addPersonalRecord(userId,
            title: title,
            category: category,
            description: description,
            mood: mood,
            metricType: metricType,
            metricValue: metricValue,
            tags: tags,
            streakContext: streakContext)
        : SupabaseService.addPersonalRecord(userId,
            title: title,
            category: category,
            description: description,
            mood: mood,
            metricType: metricType,
            metricValue: metricValue,
            tags: tags,
            streakContext: streakContext);
  }
}
