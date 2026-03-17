import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckInOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const CheckInOverlay({super.key, required this.onComplete});

  @override
  State<CheckInOverlay> createState() => _CheckInOverlayState();
}

class _CheckInOverlayState extends State<CheckInOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _xpAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack)),
    );

    _xpAnimation = Tween<double>(begin: 0, end: 50).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );

    _controller.forward().then((_) {
      // Auto-dismiss after completion
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3 * _scaleAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Icon(
                            Icons.self_improvement,
                            color: cs.primary,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'DAO HEART STRENGTHENED',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"Consistency builds the foundation of power."',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${_xpAnimation.value.toInt()} QI',
                            style: GoogleFonts.jetBrainsMono(
                              color: cs.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(width: 1, height: 24, color: cs.primary.withValues(alpha: 0.3)),
                          const SizedBox(width: 16),
                          Text(
                            '+5 STONES',
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFFFBBF24),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
