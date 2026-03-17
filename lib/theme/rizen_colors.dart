import 'package:flutter/material.dart';

/// Game-specific semantic colors that don't fit standard ColorScheme slots.
/// Access via: `Theme.of(context).extension<RizenColors>()!`
class RizenColors extends ThemeExtension<RizenColors> {
  final Color xp; // Qi Flow
  final Color rep; // Spirit Stones
  final Color danger; // Qi Deviation
  final Color accentGlow; // Jade Aura
  final Color durabilityLow;
  final Color durabilityCritical;
  // ── New tokens ────────────────────────────────────────────
  /// Dao Heart flame (warm amber)
  final Color streakFire;
  /// Talisman icon accent (soft celestial blue)
  final Color shieldBlue;
  /// Trial expiry countdown — shifts amber → orange → red by urgency
  final Color questExpiryNormal;
  final Color questExpiryUrgent;
  final Color questExpiryCritical;

  const RizenColors({
    required this.xp,
    required this.rep,
    required this.danger,
    required this.accentGlow,
    required this.durabilityLow,
    required this.durabilityCritical,
    required this.streakFire,
    required this.shieldBlue,
    required this.questExpiryNormal,
    required this.questExpiryUrgent,
    required this.questExpiryCritical,
  });

  @override
  RizenColors copyWith({
    Color? xp,
    Color? rep,
    Color? danger,
    Color? accentGlow,
    Color? durabilityLow,
    Color? durabilityCritical,
    Color? streakFire,
    Color? shieldBlue,
    Color? questExpiryNormal,
    Color? questExpiryUrgent,
    Color? questExpiryCritical,
  }) =>
      RizenColors(
        xp: xp ?? this.xp,
        rep: rep ?? this.rep,
        danger: danger ?? this.danger,
        accentGlow: accentGlow ?? this.accentGlow,
        durabilityLow: durabilityLow ?? this.durabilityLow,
        durabilityCritical: durabilityCritical ?? this.durabilityCritical,
        streakFire: streakFire ?? this.streakFire,
        shieldBlue: shieldBlue ?? this.shieldBlue,
        questExpiryNormal: questExpiryNormal ?? this.questExpiryNormal,
        questExpiryUrgent: questExpiryUrgent ?? this.questExpiryUrgent,
        questExpiryCritical: questExpiryCritical ?? this.questExpiryCritical,
      );

  @override
  RizenColors lerp(RizenColors? other, double t) => this;
}
