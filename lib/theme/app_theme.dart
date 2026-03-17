import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rizen_colors.dart';

/// Theme v3 — Dao Forge (Cultivation)
/// Designed by Gemini, implemented by Alex — 2026-03-15
class AppTheme {
  // Dao Forge palette — dark mode
  static const _primaryJade = Color(0xFF00C9A7);       // Qi Green
  static const _secondaryGold = Color(0xFFFBBF24);     // Spirit Gold
  static const _tertiaryViolet = Color(0xFF8B5CF6);    // Dao Violet
  static const _surfaceInk = Color(0xFF1A1625);        // Ink Stone
  static const _bgVoid = Color(0xFF0A0A0F);            // Void Black
  static const _outlineSmoke = Color(0xFF2A2535);      // Smoke Border
  static const _textParchment = Color(0xFFF0EDE4);     // Parchment White
  static const _textMist = Color(0xFF9590A8);          // Mist Grey
  static const _dangerBlood = Color(0xFFEF4444);       // Blood Qi Red

  // Dao Forge palette — light mode
  static const _lightPrimary = Color(0xFF0D9488);      // Deep Jade
  static const _lightSecondary = Color(0xFFD97706);    // Warm Gold
  static const _lightTertiary = Color(0xFF5B21B6);     // Deep Purple
  static const _lightSurface = Colors.white;
  static const _lightBg = Color(0xFFF0F0F5);           // Mist Grey BG
  static const _lightOutline = Color(0xFFD0D0DA);      // Soft Grey
  static const _lightTextPrimary = Color(0xFF1A1A2E);  // Ink Black
  static const _lightTextSecondary = Color(0xFF5C5C7A);
  static const _lightDanger = Color(0xFFDC2626);       // Deep Red

  // Named text styles — use these explicitly in screens for consistent hierarchy
  static TextStyle get playerNameStyle => GoogleFonts.cinzel(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: _textParchment,
  );

  static TextStyle get sectionHeaderStyle => GoogleFonts.cinzel(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.5,
    color: _textParchment,
  );

  static TextStyle get levelBadgeStyle => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get skillHintStyle => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    color: _textMist,
  );

  /// Terminal-style numbers for stats, Qi counts, damage values
  static TextStyle get statNumberStyle => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  // ── Dark theme ──────────────────────────────────────────────

  static final _darkRizenColors = RizenColors(
    xp: _primaryJade,
    rep: _secondaryGold,
    danger: _dangerBlood,
    accentGlow: const Color(0x2E00C9A7),            // 18% opacity jade glow
    durabilityLow: const Color(0xFFFB923C),
    durabilityCritical: _dangerBlood,
    streakFire: const Color(0xFFF59E0B),             // Dao Heart flame
    shieldBlue: const Color(0xFF60A5FA),             // Talisman blue
    questExpiryNormal: const Color(0xFF9590A8),      // grey
    questExpiryUrgent: const Color(0xFFFBBF24),      // gold
    questExpiryCritical: const Color(0xFFFB923C),    // orange
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primaryJade,
          onPrimary: Color(0xFF000000),
          secondary: _secondaryGold,
          onSecondary: Colors.black,
          tertiary: _tertiaryViolet,
          surface: _surfaceInk,
          outline: _outlineSmoke,
          onSurface: _textParchment,
          error: _dangerBlood,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: _bgVoid,
        extensions: [_darkRizenColors],
        textTheme: TextTheme(
          displayLarge: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.cinzel(letterSpacing: 1.5),
          bodyLarge: GoogleFonts.inter(color: _textParchment),
          bodyMedium: GoogleFonts.inter(color: _textParchment),
          labelSmall: GoogleFonts.jetBrainsMono(color: _primaryJade),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _surfaceInk,
          contentTextStyle: GoogleFonts.inter(color: _textParchment),
        ),
        cardTheme: CardThemeData(
          color: _surfaceInk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _outlineSmoke, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _bgVoid,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _outlineSmoke),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _outlineSmoke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryJade, width: 1),
          ),
          hintStyle: GoogleFonts.inter(color: _textMist),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryJade,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.cinzel(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
            shadowColor: const Color(0x4000C9A7),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryJade),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceInk,
          labelStyle: GoogleFonts.inter(color: _textParchment),
          side: const BorderSide(color: _outlineSmoke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(
          color: _outlineSmoke,
          thickness: 1,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: _primaryJade,
          unselectedLabelColor: _textMist,
          indicatorColor: _primaryJade,
          labelStyle: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.cinzel(fontSize: 11),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          linearMinHeight: 10,
          color: _primaryJade,
          linearTrackColor: Color(0xFF141218),
        ),
      );

  // ── Light theme ─────────────────────────────────────────────

  static final _lightRizenColors = RizenColors(
    xp: _lightPrimary,
    rep: _lightSecondary,
    danger: _lightDanger,
    accentGlow: const Color(0x200D9488),            // soft jade tint
    durabilityLow: const Color(0xFFF97316),
    durabilityCritical: _lightDanger,
    streakFire: const Color(0xFFF97316),
    shieldBlue: const Color(0xFF3B82F6),
    questExpiryNormal: const Color(0xFF757575),
    questExpiryUrgent: const Color(0xFFD97706),
    questExpiryCritical: const Color(0xFFF97316),
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: _lightPrimary,
          onPrimary: Colors.white,
          secondary: _lightSecondary,
          onSecondary: Colors.white,
          tertiary: _lightTertiary,
          surface: _lightSurface,
          outline: _lightOutline,
          onSurface: _lightTextPrimary,
          error: _lightDanger,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: _lightBg,
        extensions: [_lightRizenColors],
        textTheme: TextTheme(
          displayLarge: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: _lightTextPrimary),
          headlineMedium: GoogleFonts.cinzel(letterSpacing: 1.5, color: _lightTextPrimary),
          bodyLarge: GoogleFonts.inter(color: _lightTextPrimary),
          bodyMedium: GoogleFonts.inter(color: _lightTextPrimary),
          labelSmall: GoogleFonts.jetBrainsMono(color: _lightPrimary),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _lightPrimary,
          contentTextStyle: GoogleFonts.inter(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: _lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _lightOutline, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _lightOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _lightOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: _lightTextSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lightPrimary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.cinzel(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            shadowColor: const Color(0x300D9488),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _lightPrimary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _lightSurface,
          labelStyle: GoogleFonts.inter(color: _lightTextPrimary),
          side: const BorderSide(color: _lightOutline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(
          color: _lightOutline,
          thickness: 1,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: _lightPrimary,
          unselectedLabelColor: _lightTextSecondary,
          indicatorColor: _lightPrimary,
          labelStyle: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.cinzel(fontSize: 11),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          linearMinHeight: 10,
          color: _lightPrimary,
          linearTrackColor: Color(0xFFE0E0EA),
        ),
      );
}
