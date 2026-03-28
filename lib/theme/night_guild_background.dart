import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../app_state.dart';
import '../models/player_data.dart';

/// Full-screen background with time-based "Sect" imagery and ambient animations.
/// Responds to both equipped Cosmetics and the current Time Revelation.
/// Now fully adaptive for both Light (Mist) and Dark (Void) themes.
class CultivationBackground extends StatelessWidget {
  final Widget child;
  const CultivationBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder2<PlayerData, TimeRevelation>(
      first: playerNotifier,
      second: timeRevelationNotifier,
      builder: (context, player, timeSetting, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = player.equippedCosmetics['Theme'];
        final effectiveTime = _getEffectiveTime(timeSetting);

        // 1. Base Gradient Layer Logic
        List<Color> gradientColors;
        if (!isDark) {
          // Sacred Ivory (Light) Mode: Soft Parchment/Bone feel
          gradientColors = [
            const Color(0xFFFDFBF7),
            const Color(0xFFFAF8F2),
          ];
        } else if (theme == 'Shadow Environment' || theme == 'Abyssal Void') {
          gradientColors = [const Color(0xFF050508), const Color(0xFF0A0A0F)];
        } else if (theme == 'Synthwave Atmosphere' || theme == 'Celestial Realm') {
          gradientColors = [const Color(0xFF1A0B2E), const Color(0xFF0A0514)];
        } else {
          gradientColors = [const Color(0xFF0D0D12), const Color(0xFF16161D)];
        }

        return Stack(
          children: [
            // Layer 0: Base Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),

            // Layer 1: Sect Image (Adaptive Opacity)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 2),
                child: Image.asset(
                  _getSectAsset(effectiveTime),
                  key: ValueKey(effectiveTime),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  // Light mode gets a very subtle ink-wash effect (0.05)
                  // Void mode gets the standard atmospheric depth (0.4)
                  opacity: AlwaysStoppedAnimation(isDark ? 0.4 : 0.05),
                ),
              ),
            ),

            // Layer 2: Adaptive Ambient Animation
            Positioned.fill(
              child: _AmbientAnimation(time: effectiveTime, isDark: isDark),
            ),

            // Layer 3: App Content
            child,
          ],
        );
      },
    );
  }

  TimeRevelation _getEffectiveTime(TimeRevelation setting) {
    if (setting != TimeRevelation.auto) return setting;
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 8) return TimeRevelation.dawn;
    if (hour >= 8 && hour < 17) return TimeRevelation.morning;
    return TimeRevelation.evening;
  }

  String _getSectAsset(TimeRevelation time) {
    switch (time) {
      case TimeRevelation.dawn:
        return 'assets/images/dawn_sect.png';
      case TimeRevelation.morning:
        return 'assets/images/morning_sect.png';
      case TimeRevelation.evening:
      case TimeRevelation.auto:
        return 'assets/images/evening_sect.png';
    }
  }
}

/// Helper to listen to two ValueNotifiers simultaneously
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
        valueListenable: first,
        builder: (context, a, _) => ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) => builder(context, a, b, child),
        ),
      );
}

class _AmbientAnimation extends StatefulWidget {
  final TimeRevelation time;
  final bool isDark;
  const _AmbientAnimation({required this.time, required this.isDark});

  @override
  State<_AmbientAnimation> createState() => _AmbientAnimationState();
}

class _AmbientAnimationState extends State<_AmbientAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SectPainter(
            time: widget.time,
            isDark: widget.isDark,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _SectPainter extends CustomPainter {
  final TimeRevelation time;
  final bool isDark;
  final double progress;
  _SectPainter({required this.time, required this.isDark, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    // Particle colors adapt to the theme brightness
    final Color dawnColor = isDark ? Colors.orangeAccent : const Color(0xFFD97706);
    final Color morningColor = isDark ? Colors.white : const Color(0xFF0D9488);
    final Color eveningColor = isDark ? Colors.blueAccent : const Color(0xFF5B21B6);

    if (time == TimeRevelation.dawn) {
      for (int i = 0; i < 15; i++) {
        final x = random.nextDouble() * size.width;
        final startY = size.height * 0.8;
        final currentY = startY - ((progress + random.nextDouble()) % 1.0) * size.height * 0.4;
        final opacity = (1.0 - (startY - currentY) / (size.height * 0.4)).clamp(0.0, isDark ? 0.3 : 0.15);
        
        paint.color = dawnColor.withValues(alpha: opacity);
        canvas.drawCircle(Offset(x, currentY), 2 + random.nextDouble() * 3, paint);
      }
    } else if (time == TimeRevelation.morning) {
      for (int i = 0; i < 20; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final breath = math.sin(progress * math.pi * 2 + (i * 0.5)) * 0.5 + 0.5;
        
        paint.color = morningColor.withValues(alpha: breath * (isDark ? 0.05 : 0.08));
        canvas.drawCircle(Offset(x, y), 1 + random.nextDouble() * 2, paint);
      }
    } else {
      for (int i = 0; i < 25; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height * 0.6;
        final twinkle = math.sin(progress * math.pi * 4 + (i * 2.0)) * 0.5 + 0.5;
        
        paint.color = eveningColor.withValues(alpha: twinkle * (isDark ? 0.1 : 0.12));
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SectPainter oldDelegate) => true;
}
