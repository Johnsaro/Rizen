import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config.dart';
import 'main_shell.dart';
import 'models/app_config.dart';
import 'screens/auth_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/update_required_screen.dart';
import 'services/guest_session.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'app_state.dart';

// Global theme notifier — accessible from any screen
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // ── Check remote app config (maintenance / version gates) ──
  final config = await SupabaseService.loadAppConfig();

  if (config.maintenanceMode) {
    runApp(RizenApp(home: MaintenanceScreen(message: config.maintenanceMessage)));
    return;
  }

  if (compareVersions(appVersion, config.minVersion) < 0) {
    runApp(RizenApp(
      home: UpdateRequiredScreen(
        latestVersion: config.minVersion,
        message: config.updateMessage,
      ),
    ));
    return;
  }

  // ── Normal startup ──
  Widget home = const AuthScreen();
  // Track whether a soft update nudge should show after login
  final bool showUpdateNudge =
      compareVersions(appVersion, config.latestVersion) < 0;

  // Restore guest session if one was active
  await GuestSession.init();

  if (GuestSession.isActive) {
    try {
      await gameService.loadAll();
      home = const MainShell();
    } catch (e) {
      debugPrint('Guest startup error: $e');
      await GuestSession.clear();
      home = const AuthScreen();
    }
  } else {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        // Refresh the JWT if it has expired — stale tokens cause 401 on all API calls
        await Supabase.instance.client.auth.refreshSession();
        await gameService.loadAll();
        home = playerNotifier.value.name.isEmpty
            ? const OnboardingScreen()
            : const MainShell();
      } catch (e) {
        debugPrint('Startup load error: $e');
        home = const AuthScreen();
      }
    }
  }

  runApp(RizenApp(
    home: home,
    showUpdateNudge: showUpdateNudge,
    latestVersion: config.latestVersion,
    updateMessage: config.updateMessage,
  ));
}

class RizenApp extends StatelessWidget {
  final Widget home;
  final bool showUpdateNudge;
  final String latestVersion;
  final String updateMessage;

  const RizenApp({
    super.key,
    required this.home,
    this.showUpdateNudge = false,
    this.latestVersion = '',
    this.updateMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, _) => MaterialApp(
        title: 'Rizen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: showUpdateNudge
            ? _UpdateNudgeWrapper(
                latestVersion: latestVersion,
                updateMessage: updateMessage,
                child: home,
              )
            : home,
      ),
    );
  }
}

/// Wraps the home screen and shows a soft update dialog exactly once.
class _UpdateNudgeWrapper extends StatefulWidget {
  final Widget child;
  final String latestVersion;
  final String updateMessage;

  const _UpdateNudgeWrapper({
    required this.child,
    required this.latestVersion,
    required this.updateMessage,
  });

  @override
  State<_UpdateNudgeWrapper> createState() => _UpdateNudgeWrapperState();
}

class _UpdateNudgeWrapperState extends State<_UpdateNudgeWrapper> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_shown && mounted) {
        _shown = true;
        _showUpdateNudge();
      }
    });
  }

  void _showUpdateNudge() {
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
            Icon(Icons.info_outline, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Update Available',
              style: TextStyle(color: cs.onSurface, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          widget.updateMessage.isNotEmpty
              ? widget.updateMessage
              : 'A new version (v${widget.latestVersion}) is available.\nUpdate when you can for the latest features.',
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
