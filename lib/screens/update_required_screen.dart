import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';

/// Full-screen blocker shown when the installed app version is below
/// the min_version in app_config. The user must update to continue.
class UpdateRequiredScreen extends StatelessWidget {
  final String latestVersion;
  final String message;

  const UpdateRequiredScreen({
    super.key,
    required this.latestVersion,
    this.message = '',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayMessage = message.isNotEmpty
        ? message
        : 'A new version ($latestVersion) is required.\nPlease update the app to continue.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update_rounded,
                color: cs.primary,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'UPDATE REQUIRED',
                style: GoogleFonts.orbitron(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
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
              const SizedBox(height: 12),
              Text(
                'Installed: v$appVersion',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
