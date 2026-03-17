import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../config.dart';
import '../main_shell.dart';
import '../models/app_config.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'update_required_screen.dart';

/// Full-screen blocker shown when maintenance_mode is true in app_config.
/// The user cannot proceed past this screen. They can tap "Retry" to
/// re-check if maintenance has ended.
class MaintenanceScreen extends StatefulWidget {
  final String message;

  const MaintenanceScreen({super.key, this.message = ''});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      final config = await SupabaseService.loadAppConfig();
      if (!mounted) return;

      // Still in maintenance — stay here
      if (config.maintenanceMode) {
        setState(() => _checking = false);
        return;
      }

      // Maintenance ended but a force update is needed
      if (compareVersions(appVersion, config.minVersion) < 0) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => UpdateRequiredScreen(
              latestVersion: config.minVersion,
              message: config.updateMessage,
            ),
          ),
          (_) => false,
        );
        return;
      }

      // Maintenance ended — run normal startup
      Widget destination = const AuthScreen();
      try {
        await gameService.loadAll();
        destination = playerNotifier.value.name.isEmpty
            ? const OnboardingScreen()
            : const MainShell();
      } catch (_) {
        destination = const AuthScreen();
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } catch (_) {
      // Still can't reach server — stay on this screen
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayMessage = widget.message.isNotEmpty
        ? widget.message
        : 'The servers are undergoing maintenance.\nWe\'ll be back shortly.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                color: cs.secondary,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'MAINTENANCE',
                style: GoogleFonts.orbitron(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _checking ? null : _retry,
                  child: _checking
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text('RETRY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
