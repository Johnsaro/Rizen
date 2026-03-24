import 'package:flutter/material.dart';
import 'models/player_data.dart';
import 'models/quest.dart';
import 'models/game_notification.dart';
import 'models/personal_record.dart';
import 'services/game_service.dart';
import 'services/guest_session.dart';
import 'services/merchant_log_service.dart';


// Global player data — set after onboarding, read by all screens
final playerNotifier = ValueNotifier<PlayerData>(PlayerData.empty);

enum TimeRevelation { auto, dawn, morning, evening }

// Global background state — controls which sect image and animation plays
final timeRevelationNotifier = ValueNotifier<TimeRevelation>(TimeRevelation.auto);

// Check-in status for today — updated by GameService, read by MainShell nav icon
final checkedInNotifier = ValueNotifier<bool>(false);

// Notifications feed — loaded on startup, updated on key game events
final notificationsNotifier = ValueNotifier<List<GameNotification>>([]);

// Guild Hall daily quest board — GM-created quests for today only, reset each day
// Separate from questNotifier (the player's personal quest log)
final guildBoardNotifier = ValueNotifier<List<Quest>>([]);

// Global quest list — populated from Supabase on startup; empty until loadAll runs
final questNotifier = ValueNotifier<List<Quest>>([]);

// Personal Records — user-logged breakthrough moments, permanent archive
final prNotifier = ValueNotifier<List<PersonalRecord>>([]);


// Convenience getter for guest mode — use in UI guards
bool get isGuestMode => GuestSession.isActive;

// Merchant's Log — local-only expense tracker (no Supabase sync)
final merchantLogService = MerchantLogService();

// Central game state manager — all mutations go through here
final gameService = GameService(
  playerNotifier: playerNotifier,
  questNotifier: questNotifier,
  guildBoardNotifier: guildBoardNotifier,
  checkedInNotifier: checkedInNotifier,
  notificationsNotifier: notificationsNotifier,
  prNotifier: prNotifier,
);
