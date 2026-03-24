import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/guest_session.dart';
import '../screens/auth_screen.dart';

/// Tracks guest actions and shows a "Secure Your Progress" dialog
/// at defined thresholds. Max once per session.
class NagPrompt {
  static const _actionCountKey = 'guest_action_count';
  static const _launchCountKey = 'guest_launch_count';
  static bool _shownThisSession = false;

  /// Thresholds at which the nag dialog appears.
  /// After 30, triggers every 25 actions (55, 80, 105, ...).
  static bool _shouldNagAtCount(int count) {
    if (count == 5 || count == 15 || count == 30) return true;
    if (count > 30 && (count - 30) % 25 == 0) return true;
    return false;
  }

  /// Call after meaningful guest actions (quest complete, check-in, level-up).
  /// Increments the counter and shows nag if threshold is hit.
  static Future<void> maybeShow(BuildContext context) async {
    if (!GuestSession.isActive || _shownThisSession) return;

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_actionCountKey) ?? 0) + 1;
    await prefs.setInt(_actionCountKey, count);

    if (_shouldNagAtCount(count)) {
      _shownThisSession = true;
      if (context.mounted) _showDialog(context);
    }
  }

  /// Call once at app startup (in main.dart) to check launch-based trigger.
  /// Triggers every 3rd guest app launch.
  static Future<void> checkLaunch(BuildContext context) async {
    if (!GuestSession.isActive || _shownThisSession) return;

    final prefs = await SharedPreferences.getInstance();
    final launches = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, launches);

    if (launches % 3 == 0) {
      _shownThisSession = true;
      if (context.mounted) _showDialog(context);
    }
  }

  static void _showDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outline),
        ),
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Secure Your Progress',
              style: TextStyle(color: cs.onSurface, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Your journey as a Wanderer is stored locally. '
          'Create an account to keep your progress safe across devices.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('LATER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(migrateFromGuest: true),
                ),
              );
            },
            child: const Text('CREATE ACCOUNT'),
          ),
        ],
      ),
    );
  }
}
