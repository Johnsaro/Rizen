import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/player_data.dart';

/// Full-screen gradient background used by every screen in the app.
/// Wrap Scaffold's body with this widget — do NOT hardcode the gradient per screen.
/// Now responds to equipped Theme cosmetics (Celestial/Abyssal).
class CultivationBackground extends StatelessWidget {
  final Widget child;
  const CultivationBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      // NOTE: Do NOT use the child: optimization here — we need the whole tree
      // to rebuild when playerNotifier fires so Frame/Effect cosmetics apply.
      builder: (context, player, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = player.equippedCosmetics['Theme'];

        List<Color> gradientColors;
        if (!isDark) {
          gradientColors = [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
          ];
        } else if (theme == 'Shadow Environment' || theme == 'Abyssal Void') {
          // Abyssal Void / Shadow
          gradientColors = [const Color(0xFF050508), const Color(0xFF0A0A0F)];
        } else if (theme == 'Synthwave Atmosphere' || theme == 'Celestial Realm') {
          // Celestial Realm / Synthwave
          gradientColors = [const Color(0xFF1A0B2E), const Color(0xFF0A0514)];
        } else {
          // Default Cultivation Void (Ink Wash feel)
          gradientColors = [const Color(0xFF0D0D12), const Color(0xFF16161D)];
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
