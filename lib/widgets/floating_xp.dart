import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showFloatingText(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => _FloatingTextWidget(message: message),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(milliseconds: 1400), () {
    if (entry.mounted) entry.remove();
  });
}

class _FloatingTextWidget extends StatefulWidget {
  final String message;

  const _FloatingTextWidget({required this.message});

  @override
  State<_FloatingTextWidget> createState() => _FloatingTextWidgetState();
}

class _FloatingTextWidgetState extends State<_FloatingTextWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -100.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Fade in quickly, then fade out slowly
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topOffset = MediaQuery.of(context).size.height * 0.45;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          top: topOffset + _slideAnimation.value,
          child: Align(
            alignment: Alignment.center,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: cs.primary, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
