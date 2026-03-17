import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerHpBar extends StatelessWidget {
  final double fraction;
  final int current;
  final int max;

  const PlayerHpBar({
    super.key,
    required this.fraction,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barColor = fraction > 0.5
        ? Colors.green.shade400
        : fraction > 0.25
            ? Colors.yellow.shade700
            : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VITALITY',
                style: GoogleFonts.cinzel(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '$current / $max',
                style: GoogleFonts.jetBrainsMono(
                  color: cs.onSurface.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 10, color: cs.outline),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: fraction),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, value, _) => FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(height: 10, color: barColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
