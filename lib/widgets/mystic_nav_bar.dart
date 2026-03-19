import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class MysticSectNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool checkedIn;

  const MysticSectNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.checkedIn,
  });

  @override
  State<MysticSectNav> createState() => _MysticSectNavState();
}

class _MysticSectNavState extends State<MysticSectNav> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late List<AnimationController> _selectionControllers;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _selectionControllers = List.generate(5, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
        value: widget.currentIndex == index ? 1.0 : 0.0,
      );
    });
  }

  @override
  void didUpdateWidget(MysticSectNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectionControllers[oldWidget.currentIndex].reverse();
      _selectionControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    for (var controller in _selectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: 110,
      width: size.width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Layer 1: The Sacred Altar Structure ──
          CustomPaint(
            size: Size(size.width, 90),
            painter: _AltarStructurePainter(
              color: cs.surface,
              accent: cs.primary,
              outline: cs.outline,
            ),
          ),

          // ── Layer 2: Nav Items ──
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.flare, 'Core', cs),
                _buildNavItem(1, Icons.auto_stories, 'Trials', cs),
                const SizedBox(width: 70), // Center Gap
                _buildNavItem(3, Icons.castle, 'Sect', cs),
                _buildNavItem(4, Icons.psychology_alt, 'Spirit', cs),
              ],
            ),
          ),

          // ── Layer 3: The Spiritual Core (Integrated FAB) ──
          Positioned(
            bottom: 25,
            child: GestureDetector(
              onTap: () => widget.onTap(2),
              child: _buildIntegratedCore(cs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ColorScheme cs) {
    final animation = _selectionControllers[index];
    
    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, _pulseController]),
        builder: (context, _) {
          final isSelected = widget.currentIndex == index;
          final value = animation.value;
          final pulse = _pulseController.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, -5 * value),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow Aura — Using direct color alpha instead of Opacity widget (Impeller safe)
                    if (value > 0.01)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: value * (0.3 + (pulse * 0.2))),
                              blurRadius: 15 * value,
                              spreadRadius: 2 * value,
                            ),
                          ],
                        ),
                      ),
                    
                    // Floating Particles for Active Tab
                    if (isSelected)
                      ...List.generate(2, (i) => _QiDrift(color: cs.primary, seed: i + index * 10)),

                    Icon(
                      icon,
                      size: 22 + (4 * value),
                      color: Color.lerp(
                        cs.onSurface.withValues(alpha: 0.35),
                        cs.primary,
                        value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.cinzel(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color.lerp(
                    cs.onSurface.withValues(alpha: 0.35),
                    cs.primary,
                    value,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntegratedCore(ColorScheme cs) {
    final isActive = widget.currentIndex == 2;
    final sealColor = widget.checkedIn ? cs.secondary : cs.primary;
    final pulse = _pulseController.value;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Rotating Rune Ring (Outer)
        RotationTransition(
          turns: _rotationController,
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _RuneCirclePainter(color: sealColor.withValues(alpha: 0.15)),
          ),
        ),

        // 2. Spiritual Formation (Inner)
        RotationTransition(
          turns: Tween(begin: 1.0, end: 0.0).animate(_rotationController),
          child: CustomPaint(
            size: const Size(75, 75),
            painter: _SpiritualFormationPainter(color: sealColor.withValues(alpha: 0.25)),
          ),
        ),

        // 3. The Core Seal Artifact
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surface,
            border: Border.all(
              color: sealColor.withValues(alpha: isActive ? 1.0 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              // Layered Glow
              BoxShadow(
                color: sealColor.withValues(alpha: 0.2 + (pulse * 0.2)),
                blurRadius: 10 + (pulse * 10),
                spreadRadius: 1 + (pulse * 3),
              ),
              if (isActive)
                BoxShadow(
                  color: sealColor.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              widget.checkedIn ? Icons.fort : Icons.bolt,
              color: sealColor,
              size: 30,
            ),
          ),
        ),

        // 4. Energy Pulses
        if (isActive)
          ...List.generate(3, (i) => _QiDrift(color: sealColor, seed: i + 99, isCore: true)),
      ],
    );
  }
}

class _AltarStructurePainter extends CustomPainter {
  final Color color;
  final Color accent;
  final Color outline;
  _AltarStructurePainter({required this.color, required this.accent, required this.outline});

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = color.computeLuminance() < 0.5;
    
    // Premium Sacred Material: Polished Jade (Light) or Ink Stone (Dark)
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark 
          ? [color.withValues(alpha: 0.95), color.withValues(alpha: 0.85)]
          : [const Color(0xFFFAF8F2), const Color(0xFFF2EEE0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.3 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final path = Path();

    // Sacred Altar Geometry (Stepped Design)
    path.moveTo(0, size.height);
    path.lineTo(0, 30);
    path.quadraticBezierTo(size.width * 0.1, 15, size.width * 0.25, 20);
    path.lineTo(size.width * 0.35, 20);
    // Center Dip for Core
    path.quadraticBezierTo(size.width * 0.5, 45, size.width * 0.65, 20);
    path.lineTo(size.width * 0.75, 20);
    path.quadraticBezierTo(size.width * 0.9, 15, size.width, 30);
    path.lineTo(size.width, size.height);
    path.close();

    // Draw main body with soft shadow
    canvas.drawShadow(path, isDark ? Colors.black : const Color(0x20000000), 15, true);
    canvas.drawPath(path, paint);

    // Golden/Jade Spiritual Lines (Filigree)
    final filigreePath = Path();
    filigreePath.moveTo(0, 32);
    filigreePath.quadraticBezierTo(size.width * 0.1, 17, size.width * 0.25, 22);
    filigreePath.lineTo(size.width * 0.35, 22);
    canvas.drawPath(filigreePath, linePaint);

    final rightFiligree = Path();
    rightFiligree.moveTo(size.width, 32);
    rightFiligree.quadraticBezierTo(size.width * 0.9, 17, size.width * 0.75, 22);
    rightFiligree.lineTo(size.width * 0.65, 22);
    canvas.drawPath(rightFiligree, linePaint);

    // Top subtle highlight line
    canvas.drawPath(
      path, 
      Paint()
        ..color = isDark ? accent.withValues(alpha: 0.15) : const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RuneCirclePainter extends CustomPainter {
  final Color color;
  _RuneCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    canvas.drawCircle(center, radius, paint);
    
    // Abstract Rune Symbols
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6);
      final pos = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + math.pi/2);
      
      // Paint a "Rune" (simple geometric combo)
      final rPath = Path();
      rPath.moveTo(-3, 0);
      rPath.lineTo(3, 0);
      rPath.moveTo(0, -2);
      rPath.lineTo(0, 2);
      canvas.drawPath(rPath, paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpiritualFormationPainter extends CustomPainter {
  final Color color;
  _SpiritualFormationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw a star/formation pattern
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      
      // Connecting lines to center
      canvas.drawLine(center, point, paint..color = color.withValues(alpha: 0.1));
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, radius * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QiDrift extends StatefulWidget {
  final Color color;
  final int seed;
  final bool isCore;
  const _QiDrift({required this.color, required this.seed, this.isCore = false});

  @override
  State<_QiDrift> createState() => _QiDriftState();
}

class _QiDriftState extends State<_QiDrift> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _xStart;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed);
    _xStart = (r.nextDouble() - 0.5) * (widget.isCore ? 60 : 30);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + r.nextInt(1000)),
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
        final v = _controller.value;
        final opacity = (1.0 - v).clamp(0.0, 1.0) * 0.5;
        
        return Positioned(
          top: (widget.isCore ? 30 : 0) - (v * 40),
          left: (widget.isCore ? 50 : 20) + _xStart + (math.sin(v * 5) * 5),
          child: Container(
            width: 2 + (widget.isCore ? 2 : 0),
            height: 2 + (widget.isCore ? 2 : 0),
            decoration: BoxDecoration(
              // Using color alpha instead of Opacity widget
              color: widget.color.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: opacity),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
