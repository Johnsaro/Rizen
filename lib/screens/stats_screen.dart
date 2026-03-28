import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart' show PlayerData, CultivationRealms;
import '../theme/night_guild_background.dart';
import '../widgets/radar_chart.dart';
import '../widgets/glass_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      builder: (_, player, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: CultivationBackground(
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: _buildTopBar(cs),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('CULTIVATION BASE', cs),
                      const SizedBox(height: 8),
                      _buildHunterLicense(cs, player),
                      const SizedBox(height: 24),
                      
                      _sectionLabel('DAO MASTERY', cs),
                      const SizedBox(height: 8),
                      _buildClassSection('PRIMARY', player.mainPath, cs, player),
                      const SizedBox(height: 32),

                      _sectionLabel('ENLIGHTENMENT SKILLS', cs),
                      const SizedBox(height: 16),
                      _buildRadarChartSection(cs, player),
                      const SizedBox(height: 32),

                      _sectionLabel('SPIRITUAL ARTIFACTS', cs),
                      const SizedBox(height: 8),
                      _buildWeaponGrid(context, cs, player),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        'CULTIVATION',
        style: GoogleFonts.cinzel(
          color: cs.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme cs) {
    return Text(
      label,
      style: GoogleFonts.cinzel(
        color: cs.onSurface.withValues(alpha: 0.35),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildHunterLicense(ColorScheme cs, PlayerData player) {
    final progress = player.maxQi > 0 ? player.qi / player.maxQi : 0.0;
    final frame = player.equippedCosmetics['Frame'];

    BoxDecoration decoration;
    if (frame == 'Guild Title Frame') {
      decoration = BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2), // Gold
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      );
    } else if (frame == 'Cyber Frame') {
      decoration = BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: decoration.boxShadow,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 16.0,
        backgroundColor: cs.surface.withValues(alpha: 0.25),
        borderColor: decoration.border?.top.color ?? cs.primary.withValues(alpha: 0.3),
        blurRadius: 15.0,
        child: Row(
        children: [
          // Avatar glowing orb
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.8), width: 2),
                  color: cs.surface,
                ),
                child: Center(
                  child: Icon(
                    Icons.badge_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        player.name.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          color: cs.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        CultivationRealms.shortDisplayFor(player.level),
                        style: GoogleFonts.cinzel(
                          color: cs.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.mainPath,
                  style: GoogleFonts.jetBrainsMono(
                    color: cs.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CultivationRealms.nameFor(player.level)} — ${CultivationRealms.subStageFor(CultivationRealms.rankFor(player.level))} Stage',
                  style: GoogleFonts.jetBrainsMono(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QI FLOW',
                      style: GoogleFonts.cinzel(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${player.qi.toInt()} / ${player.maxQi.toInt()}',
                      style: GoogleFonts.jetBrainsMono(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: player.equippedCosmetics['Effect'] == 'XP Flame Trail' ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        player.equippedCosmetics['Effect'] == 'XP Flame Trail' ? Colors.deepOrangeAccent : cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildClassSection(String label, String className, ColorScheme cs, PlayerData player) {
    final xp = player.pathQi[className] ?? 0.0;
    final max = player.pathMaxQi(className);
    final lv = player.pathLevel[className] ?? 1;
    final progress = max > 0 ? xp / max : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12.0,
      backgroundColor: cs.surface.withValues(alpha: 0.3),
      borderColor: cs.primary.withValues(alpha: 0.4),
      blurRadius: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.cinzel(
                  color: cs.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                Icons.stars,
                size: 14,
                color: cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            className.split(' ').first.toUpperCase(),
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Lv. $lv',
            style: GoogleFonts.jetBrainsMono(
              color: cs.secondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Stats per class: each entry is (stat name, base multiplier 0.0-1.0)
  static const _classStats = <String, List<(String, double)>>{
    'Shadow Arts':       [('Recon', 0.9), ('Exploit', 0.8), ('Enum', 0.7), ('Stealth', 0.6)],
    'Formation Master':  [('Frontend', 0.9), ('Backend', 0.7), ('Design', 0.8), ('Speed', 0.5)],
    'Artifact Refiner':  [('Performance', 0.9), ('UI Polish', 0.8), ('Cross-Platform', 0.7)],
    'Realm Architect':   [('Logic', 0.9), ('Math', 0.7), ('Assets', 0.6), ('Speed', 0.8)],
    'Body Cultivator':   [('Strength', 0.9), ('Endurance', 0.8), ('Discipline', 0.7), ('Vitality', 0.6)],
    'Scripture Keeper':  [('Focus', 0.9), ('Retention', 0.8), ('Analysis', 0.7), ('Comprehension', 0.6)],
    'Inscription Master':[('Creativity', 0.9), ('Craft', 0.8), ('Flow', 0.7), ('Precision', 0.6)],
  };

  static const _defaultStats = <(String, double)>[
    ('Adapt', 0.8), ('Focus', 0.7), ('Speed', 0.6), ('Logic', 0.7),
  ];

  List<(String, double)> _statsForClass(String className, int level) {
    final defs = _classStats[className] ?? _defaultStats;
    // Map the multiplier to a 0.0-1.0 scale based on level scaling, capped at 1.0
    return defs.map((s) {
      final scaled = (s.$2 * (1.0 + (level * 0.1))).clamp(0.1, 1.0);
      return (s.$1, scaled);
    }).toList();
  }

  Widget _buildRadarChartSection(ColorScheme cs, PlayerData player) {
    final mainLevel = player.pathLevel[player.mainPath] ?? 1;
    final stats = _statsForClass(player.mainPath, mainLevel);

    // If there's less than 3 stats, radar chart fails to draw a polygon. Ensure min 3.
    final renderStats = stats.length >= 3 ? stats : _defaultStats;

    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        borderRadius: 16.0,
        backgroundColor: cs.surface.withValues(alpha: 0.2),
        borderColor: cs.primary.withValues(alpha: 0.3),
        blurRadius: 12.0,
        child: RadarChart(
          stats: renderStats,
          themeColor: cs.primary,
        ),
      ),
    );
  }

  static const _weaponIcons = <String, IconData>{
    'Recon Blade':   Icons.bolt,
    'Debug Shield':  Icons.auto_awesome,
    'Enum Staff':    Icons.manage_search,
    'Stealth Cloak': Icons.visibility_off,
  };

  Widget _buildWeaponGrid(BuildContext context, ColorScheme cs, PlayerData player) {
    final ownedWeapons = player.inventory.keys
        .where((name) => _weaponIcons.containsKey(name))
        .toList();

    if (ownedWeapons.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 12.0,
        backgroundColor: cs.surface.withValues(alpha: 0.3),
        borderColor: cs.outline.withValues(alpha: 0.5),
        blurRadius: 8.0,
        child: Text(
          'Artifact Collection Empty.',
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            color: cs.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: ownedWeapons.length,
      itemBuilder: (context, index) {
        final name = ownedWeapons[index];
        final icon = _weaponIcons[name] ?? Icons.flash_on;
        final isEquipped = player.equippedWeapon == name;
        final durability = 1.0; // In a real app, from state

        final hasNeon = isEquipped && player.equippedCosmetics['Effect'] == 'Neon Arsenal';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: hasNeon ? [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 10.0,
            backgroundColor: isEquipped ? cs.primary.withValues(alpha: 0.15) : cs.surface.withValues(alpha: 0.25),
            borderColor: hasNeon ? cs.primary : (isEquipped ? cs.primary.withValues(alpha: 0.6) : cs.outline.withValues(alpha: 0.4)),
            blurRadius: 8.0,
            child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: isEquipped ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cinzel(
                        color: cs.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: durability,
                        minHeight: 3,
                        backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          durability > 0.5 ? cs.primary : Colors.red,
                        ),
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
    );
  }
}
