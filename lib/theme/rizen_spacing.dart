import 'package:flutter/material.dart';

/// The Rizen Spacing System ("Dao Rhythm")
/// Provides a consistent multiplier-based scale to avoid hardcoded padding values.
class RizenSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Convenient Edge Insets
  static const EdgeInsets defaultPadding = EdgeInsets.all(m);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: m);
}
