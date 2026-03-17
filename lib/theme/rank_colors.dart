import 'package:flutter/material.dart';

/// Single canonical source of truth for rank badge colors.
/// Do NOT define rank colors in individual screens.
/// Adjusted for Cultivation aesthetic.
Color rankColor(String rank) {
  switch (rank.toUpperCase()) {
    case 'F':
      return const Color(0xFF8A8599); // Muted Mist — mortal
    case 'E':
      return const Color(0xFF2DD4BF); // Pale Jade — qi gathering
    case 'D':
      return const Color(0xFF60A5FA); // Soft Qi Blue
    case 'C':
      return const Color(0xFF8B5CF6); // Spirit Violet — foundation
    case 'B':
      return const Color(0xFF7C3AED); // Deep Amethyst
    case 'A':
      return const Color(0xFFFBBF24); // Heavenly Gold — core formation
    case 'S':
      return const Color(0xFFF97316); // Crimson Flame — nascent soul
    case 'SS':
      return const Color(0xFFFB923C); // Phoenix Orange
    case 'SSS':
      return const Color(0xFFFDE68A); // Immortal Gold — radiant, divine
    default:
      return const Color(0xFF8A8599); // fallback: muted mist
  }
}
