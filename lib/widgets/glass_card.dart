import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphic container that creates volume and depth
/// without breaking the dark mode aesthetic. Replaces standard Flat Containers.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 14.0,
    this.backgroundColor,
    this.borderColor,
    this.blurRadius = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Default colors based on the current context (Ink Stone + Smoke Outline for Dark Mode)
    final bgColor = backgroundColor ?? cs.surface.withValues(alpha: 0.6);
    final outlineColor = borderColor ?? cs.outline.withValues(alpha: 0.8);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: outlineColor, width: 1.0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
