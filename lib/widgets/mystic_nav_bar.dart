import 'dart:ui';
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
      duration: const Duration(seconds: 40), // Slower rotation
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
      height: 130,
      width: size.width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Layer 1: The Sacred Altar Structure ──
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: _AltarClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: size.width,
                  height: 100,
                  color: cs.brightness == Brightness.dark
                      ? cs.surface.withValues(alpha: 0.65)
                      : cs.surface.withValues(alpha: 0.35), // Translucent in light mode
                  child: CustomPaint(
                    painter: _AltarBorderPainter(
                      accent: cs.primary,
                      outline: cs.outline,
                      isDark: cs.brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 2: Nav Items ──
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(0, Icons.spa_outlined, Icons.spa, 'Core', cs),
                _buildNavItem(1, Icons.military_tech_outlined, Icons.military_tech, 'Trials', cs),
                const SizedBox(width: 70), // Center Gap
                _buildNavItem(3, Icons.account_balance_outlined, Icons.account_balance, 'Sect', cs),
                _buildNavItem(4, Icons.self_improvement_outlined, Icons.self_improvement, 'Spirit', cs),
              ],
            ),
          ),

          // ── Layer 3: The Spiritual Core (Integrated FAB) ──
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: () => widget.onTap(2),
              child: _buildIntegratedCore(cs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData hollowIcon, IconData solidIcon, String label, ColorScheme cs) {
    final animation = _selectionControllers[index];
    
    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, _pulseController]),
        builder: (context, _) {
          final value = animation.value;
          
          return Container(
            width: 50,
            color: Colors.transparent, // expand hit area
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hollow Icon (Fades out)
                    Opacity(
                      opacity: 1.0 - value,
                      child: Icon(
                        hollowIcon,
                        size: 24,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    // Solid Icon (Fades in & scales slightly)
                    Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 1.0 + (0.15 * value),
                        child: Icon(
                          solidIcon,
                          size: 24,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 4),
                // Glowing Animated Line Trace
                Container(
                  width: 24 * value, // Expands from 0
                  height: 2,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: value),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: value * 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                )
              ],
            ),
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
            size: const Size(110, 110),
            painter: _RuneCirclePainter(color: sealColor.withValues(alpha: 0.2)),
          ),
        ),

        // 2. Spiritual Formation (Inner)
        RotationTransition(
          turns: Tween(begin: 1.0, end: 0.0).animate(_rotationController),
          child: CustomPaint(
            size: const Size(85, 85),
            painter: _SpiritualFormationPainter(color: sealColor.withValues(alpha: 0.3)),
          ),
        ),

        // 3. The Core Seal Artifact
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surface.withValues(alpha: 0.85),
            border: Border.all(
              color: sealColor.withValues(alpha: isActive ? 1.0 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.surface.withValues(alpha: 0.5), // inner heavy drop shadow
                blurRadius: 10,
                spreadRadius: -4,
              ),
              // Layered Glow
              BoxShadow(
                color: sealColor.withValues(alpha: 0.15 + (pulse * 0.15)),
                blurRadius: 12 + (pulse * 8),
                spreadRadius: 1 + (pulse * 3),
              ),
              if (isActive)
                BoxShadow(
                  color: sealColor.withValues(alpha: 0.1),
                  blurRadius: 25,
                  spreadRadius: 8,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
                child: Icon(
                  widget.checkedIn ? Icons.shield : Icons.bolt,
                  color: sealColor,
                  size: 32,
                ),
              ),
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

class _AltarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
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
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AltarBorderPainter extends CustomPainter {
  final Color accent;
  final Color outline;
  final bool isDark;
  _AltarBorderPainter({required this.accent, required this.outline, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.4 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
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

    // Top border line
    final topBorderPath = _AltarClipper().getClip(size);
    canvas.drawPath(
      topBorderPath, 
      Paint()
        ..color = isDark ? outline.withValues(alpha: 0.5) : const Color(0xFFE5E1D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
    );
    // Top highlight rim
    canvas.drawPath(
      topBorderPath, 
      Paint()
        ..color = isDark ? accent.withValues(alpha: 0.1) : Colors.white
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
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Abstract Rune Symbols
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6);
      final pos = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + math.pi/2);
      
      final rPath = Path();
      rPath.moveTo(-4, 0);
      rPath.lineTo(4, 0);
      rPath.moveTo(0, -3);
      rPath.lineTo(0, 3);
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
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.0;
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
      canvas.drawLine(center, point, paint..color = color.withValues(alpha: 0.2));
    }
    path.close();
    canvas.drawPath(path, paint);
    
    // Inner geometric circle
    final innerPaint = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    canvas.drawCircle(center, radius * 0.45, innerPaint);
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
        final opacity = (1.0 - v).clamp(0.0, 1.0) * 0.6;
        
        return Positioned(
          top: (widget.isCore ? 30 : 0) - (v * 45),
          left: (widget.isCore ? 50 : 20) + _xStart + (math.sin(v * 6) * 6),
          child: Container(
            width: 3 + (widget.isCore ? 2.0 : 0.0),
            height: 3 + (widget.isCore ? 2.0 : 0.0),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: opacity),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
