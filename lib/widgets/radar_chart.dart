import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RadarChart extends StatelessWidget {
  final List<(String, double)> stats;
  final Color themeColor;

  const RadarChart({
    super.key,
    required this.stats,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: CustomPaint(
        size: const Size(double.infinity, 220),
        painter: _RadarPainter(
          stats: stats,
          themeColor: themeColor,
          labelStyle: GoogleFonts.jetBrainsMono(
            color: themeColor.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<(String, double)> stats;
  final Color themeColor;
  final TextStyle labelStyle;

  _RadarPainter({
    required this.stats,
    required this.themeColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final n = stats.length;
    if (n < 3) return;

    final angleStep = 2 * pi / n;
    const startAngle = -pi / 2;

    // Grid rings
    final gridPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = startAngle + angleStep * i;
        final point = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis lines
    final axisPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, end, axisPaint);
    }

    // Data polygon
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final value = stats[i].$2.clamp(0.0, 1.0);
      final angle = startAngle + angleStep * i;
      final r = radius * value;
      final point = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Data points
    final dotPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < n; i++) {
      final value = stats[i].$2.clamp(0.0, 1.0);
      final angle = startAngle + angleStep * i;
      final r = radius * value;
      final point = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
      canvas.drawCircle(point, 3, dotPaint);
    }

    // Labels
    for (var i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 18;
      final point = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final tp = TextPainter(
        text: TextSpan(text: stats[i].$1, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        point.dx - tp.width / 2,
        point.dy - tp.height / 2,
      );
      tp.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      stats != oldDelegate.stats || themeColor != oldDelegate.themeColor;
}
