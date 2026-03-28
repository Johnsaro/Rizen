import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart' show PlayerData, CultivationRealms;
import '../models/achievement.dart';
import '../theme/night_guild_background.dart';
import 'settings_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      builder: (_, player, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: CultivationBackground(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 340.0,
                backgroundColor: Colors.transparent,
                pinned: true,
                stretch: true,
                elevation: 0,
                title: Text(
                  'IDENTITY',
                  style: GoogleFonts.cinzel(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: cs.onSurface.withValues(alpha: 0.8)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Dark gradient overlay for readability of pinned title
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60.0),
                          child: _buildAvatarCard(context, cs, player),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSection('DAO PATHS', _buildClassTracks(cs, player), cs),
                    const SizedBox(height: 16),
                    _buildSection('DAO PROGRESS', _buildCoreStats(cs, player), cs),
                    const SizedBox(height: 16),
                    _buildSection('DAO HEART', _buildDaoHeartSection(cs, player), cs),
                    const SizedBox(height: 16),
                    _buildSection('SPIRITUAL ARTIFACTS', _buildArsenal(cs, player), cs),
                    const SizedBox(height: 16),
                    _buildSection('★  FEATURED MERIT', _buildFeaturedAchievement(context, cs, player), cs),
                    const SizedBox(height: 16),
                    _buildSection('HEAVENLY MERITS', _buildBadges(context, cs, player), cs),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _buildTopBar in favor of SliverAppBar

  Widget _buildAvatarCard(
    BuildContext context,
    ColorScheme cs,
    PlayerData player,
  ) {
    final name = player.name;
    final level = player.level;
    final mainClass = player.mainPath;
    final title = player.title;

    final frame = player.equippedCosmetics['Frame'];

    BoxDecoration decoration;
    if (frame == 'Guild Title Frame') {
      decoration = BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline, width: 1),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: decoration.boxShadow,
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24),
        borderRadius: 12.0,
        backgroundColor: cs.surface.withValues(alpha: 0.1),
        borderColor: decoration.border?.top.color ?? cs.outline,
        blurRadius: 15.0,
        child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              FaIcon(
                FontAwesomeIcons.userNinja,
                size: 60,
                color: cs.surface.withValues(alpha: 0.8),
              ),
              FaIcon(
                FontAwesomeIcons.userNinja,
                size: 64,
                color: cs.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditNameDialog(context, player),
                child: Icon(
                  FontAwesomeIcons.penToSquare,
                  size: 14,
                  color: cs.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title.isNotEmpty ? '"$title"' : '"No title yet"',
            style: TextStyle(
              color: cs.primary.withValues(alpha: 0.9),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(CultivationRealms.shortDisplayFor(level), cs),
              const SizedBox(width: 8),
              _chip(mainClass, cs),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${CultivationRealms.subStageFor(CultivationRealms.rankFor(level))} Stage',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _chip(String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.secondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Dao Heart Section ──────────────────────────────────

  static const _daoStates = ['Wavering', 'Steady', 'Firm', 'Unyielding', 'Immovable'];

  static const _daoColors = <String, Color>{
    'Wavering':   Color(0xFF9590A8),
    'Steady':     Color(0xFFFB923C),
    'Firm':       Color(0xFFF59E0B),
    'Unyielding': Color(0xFFFBBF24),
    'Immovable':  Color(0xFF00C9A7),
  };

  static const _daoFlavor = <String, String>{
    'Wavering':   'Your foundation is unstable. Keep showing up.',
    'Steady':     'The path is forming beneath your feet.',
    'Firm':       'Lesser demons dare not approach.',
    'Unyielding': 'Even heaven acknowledges your resolve.',
    'Immovable':  'Your Dao Heart cannot be shaken.',
  };

  Widget _buildDaoHeartSection(ColorScheme cs, PlayerData player) {
    final state = player.daoHeartState;
    final stateColor = _daoColors[state] ?? const Color(0xFF9590A8);
    final bonus = PlayerData.qiBonusForStreak(player.daoHeartStreak);
    final bonusPercent = (bonus * 100).round();
    final stateIndex = _daoStates.indexOf(state).clamp(0, 4);
    final stateIcon = (state == 'Unyielding' || state == 'Immovable')
        ? Icons.whatshot
        : Icons.local_fire_department;

    return Column(
      children: [
        // Current state row
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stateColor.withValues(alpha: 0.15),
              ),
              child: Icon(stateIcon, color: stateColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.toUpperCase(),
                    style: GoogleFonts.cinzel(
                      color: stateColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _daoFlavor[state] ?? '',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+$bonusPercent%',
                  style: GoogleFonts.jetBrainsMono(
                    color: stateColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Qi Bonus',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 5-dot progression bar
        SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth - 40; // 20px padding each side
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background line
                  Positioned(
                    left: 20,
                    right: 20,
                    child: Container(height: 2, color: cs.outline),
                  ),
                  // Active line
                  if (stateIndex > 0)
                    Positioned(
                      left: 20,
                      child: Container(
                        height: 2,
                        width: trackWidth * (stateIndex / 4),
                        color: stateColor,
                      ),
                    ),
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final isActive = i <= stateIndex;
                      final isCurrent = i == stateIndex;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isCurrent ? 12 : 10,
                            height: isCurrent ? 12 : 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? stateColor : Colors.transparent,
                              border: Border.all(
                                color: isActive ? stateColor : cs.outline,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _daoStates[i],
                            style: TextStyle(
                              color: isCurrent
                                  ? cs.onSurface
                                  : cs.onSurface.withValues(alpha: 0.3),
                              fontSize: 8,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Streak counter
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, color: const Color(0xFFFB923C), size: 16),
            const SizedBox(width: 4),
            Text(
              '${player.daoHeartStreak} day streak',
              style: GoogleFonts.jetBrainsMono(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Qi Deviation card (conditional)
        if (player.isQiDeviationActive) ...[
          const SizedBox(height: 12),
          _buildDeviationCard(cs, player),
        ],
      ],
    );
  }

  Widget _buildDeviationCard(ColorScheme cs, PlayerData player) {
    const devColor = Color(0xFFEF4444);
    const jadeGreen = Color(0xFF00C9A7);

    String remaining = '';
    final expiry = DateTime.tryParse(player.qiDeviationExpiry);
    if (expiry != null) {
      final diff = expiry.difference(DateTime.now());
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      if (h > 0) {
        remaining = '${h}h ${m}m remaining';
      } else if (m > 0) {
        remaining = '${m}m remaining';
      } else {
        remaining = 'expiring...';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: devColor.withValues(alpha: 0.08),
        border: Border.all(color: devColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: devColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'QI DEVIATION ACTIVE',
                style: GoogleFonts.cinzel(
                  color: devColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Qi gain reduced by 50%. Complete 3 trials to stabilize.',
            style: TextStyle(
              color: devColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 3 trial circles
              ...List.generate(3, (i) {
                final completed = i < player.qiDeviationTrials;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? jadeGreen : Colors.transparent,
                      border: Border.all(
                        color: completed ? jadeGreen : devColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Text(
                remaining,
                style: GoogleFonts.jetBrainsMono(
                  color: devColor.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.35) : const Color(0xFF4B5563)),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 12.0,
          backgroundColor: cs.surface.withValues(alpha: 0.3),
          borderColor: cs.primary.withValues(alpha: 0.25),
          blurRadius: 10.0,
          child: content,
        ),
      ],
    );
  }

  Widget _buildClassTracks(ColorScheme cs, PlayerData player) {
    final mainXp = player.pathQi[player.mainPath] ?? 0.0;
    final mainMax = player.pathMaxQi(player.mainPath);
    final mainLv = player.pathLevel[player.mainPath] ?? 1;

    return Column(
      children: [
        _classTrackRow(
          player.mainPath,
          mainMax > 0 ? mainXp / mainMax : 0.0,
          mainLv,
          cs,
        ),
      ],
    );
  }

  Widget _classTrackRow(
    String className,
    double progress,
    int level,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                className,
                style: TextStyle(
                  color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.7) : const Color(0xFF4B5563)),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Lv.$level',
          style: TextStyle(
            color: cs.secondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Top 3 stats per path — (label, base multiplier).
  // Higher multiplier = scales faster with level.
  static const _pathCoreStats = <String, List<(String, double)>>{
    'Shadow Arts':        [('Recon', 0.9),       ('Exploit', 0.8),     ('Stealth', 0.7)],
    'Realm Architect':    [('Logic', 0.9),       ('Math', 0.7),        ('Speed', 0.8)],
    'Formation Master':   [('Frontend', 0.9),    ('Backend', 0.7),     ('Design', 0.8)],
    'Artifact Refiner':   [('Performance', 0.9), ('UI Polish', 0.8),   ('Cross-Platform', 0.7)],
    'Body Cultivator':    [('Strength', 0.9),    ('Endurance', 0.8),   ('Discipline', 0.7)],
    'Scripture Keeper':   [('Focus', 0.9),       ('Retention', 0.8),   ('Analysis', 0.7)],
    'Inscription Master': [('Creativity', 0.9),  ('Craft', 0.8),      ('Flow', 0.7)],
  };

  static const _defaultCoreStats = [('Adapt', 0.8), ('Focus', 0.7), ('Speed', 0.6)];

  Widget _buildCoreStats(ColorScheme cs, PlayerData player) {
    final mainLevel = player.pathLevel[player.mainPath] ?? 1;
    final stats = _pathCoreStats[player.mainPath] ?? _defaultCoreStats;

    final rows = <Widget>[];
    for (int i = 0; i < stats.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      final (label, multiplier) = stats[i];
      final value = (mainLevel * multiplier * 10 / 5).round().clamp(0, 10);
      rows.add(_statRow(label, value, 10, cs));
    }

    return Column(children: rows);
  }

  Widget _statRow(String label, int value, int max, ColorScheme cs) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.6) : const Color(0xFF4B5563)),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: max > 0 ? value / max : 0,
              minHeight: 5,
              backgroundColor: cs.onSurface.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: TextStyle(
            color: cs.secondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static const _weaponIcons = <String, IconData>{
    'Recon Blade': FontAwesomeIcons.khanda,
    'Debug Shield': FontAwesomeIcons.shieldHalved,
    'Enum Staff': FontAwesomeIcons.wandMagicSparkles,
    'Stealth Cloak': FontAwesomeIcons.userSecret,
    'Code Forge': FontAwesomeIcons.hammer,
    'Exploit Dagger': FontAwesomeIcons.khanda,
  };

  Widget _buildArsenal(ColorScheme cs, PlayerData player) {
    final ownedWeapons = player.inventory.keys
        .where((name) => _weaponIcons.containsKey(name))
        .toList();

    if (ownedWeapons.isEmpty) {
      return Text(
        'No weapons owned — visit the shop.',
        style: TextStyle(
          color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.35) : const Color(0xFF4B5563)),
          fontSize: 12,
          height: 1.5,
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < ownedWeapons.length; i++) ...[
          _arsenalRow(
            ownedWeapons[i],
            _weaponIcons[ownedWeapons[i]] ?? Icons.flash_on,
            player.equippedWeapon == ownedWeapons[i],
            cs,
          ),
          if (i < ownedWeapons.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _arsenalRow(
    String name,
    IconData icon,
    bool isEquipped,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Icon(icon, color: cs.secondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.7) : const Color(0xFF4B5563)),
              fontSize: 13,
            ),
          ),
        ),
        if (isEquipped)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.secondary.withValues(alpha: 0.4)),
            ),
            child: Text(
              'EQ',
              style: TextStyle(
                color: cs.secondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedAchievement(BuildContext context, ColorScheme cs, PlayerData player) {
    final featuredId = player.featuredAchievement;
    final featured = featuredId.isNotEmpty ? AchievementCatalog.get(featuredId) : null;
    final hasUnlocked = player.achievements.isNotEmpty;

    return GestureDetector(
      onTap: hasUnlocked ? () => _showFeaturedPicker(context, player) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              featured?.icon ?? Icons.emoji_events,
              color: cs.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featured?.name ?? 'No featured achievement yet',
                  style: TextStyle(
                    color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.7) : const Color(0xFF4B5563)),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  featured?.description ?? 'Complete quests to earn achievements',
                  style: TextStyle(
                    color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.35) : const Color(0xFF4B5563)),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (hasUnlocked)
            Icon(Icons.chevron_right, color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.3) : const Color(0xFF4B5563)), size: 20),
        ],
      ),
    );
  }

  void _showFeaturedPicker(BuildContext context, PlayerData player) {
    final cs = Theme.of(context).colorScheme;
    final unlockedIds = player.achievements.keys.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT FEATURED ACHIEVEMENT',
                  style: TextStyle(
                    color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.5) : const Color(0xFF4B5563)),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                if (saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  ...unlockedIds.map((id) {
                    final a = AchievementCatalog.get(id);
                    if (a == null) return const SizedBox.shrink();
                    final isSelected = player.featuredAchievement == id;
                    return ListTile(
                      leading: Icon(a.icon, color: isSelected ? cs.secondary : (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.5) : const Color(0xFF4B5563))),
                      title: Text(
                        a.name,
                        style: TextStyle(
                          color: isSelected ? cs.secondary : cs.onSurface,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        a.description,
                        style: TextStyle(color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)), fontSize: 11),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: cs.secondary, size: 20)
                          : null,
                      onTap: () async {
                        setSheetState(() => saving = true);
                        final updated = player.copyWith(featuredAchievement: id);
                        await gameService.updatePlayer(updated);
                        if (!ctx.mounted) return;
                        if (gameService.errorNotifier.value != null) {
                          setSheetState(() => saving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Failed to save — try again')),
                          );
                        } else {
                          Navigator.pop(ctx);
                        }
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadges(BuildContext context, ColorScheme cs, PlayerData player) {
    final catalog = AchievementCatalog.all;

    if (player.achievements.isEmpty) {
      return Text(
        'No badges yet — complete quests and milestones to earn them.',
        style: TextStyle(
          color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.35) : const Color(0xFF4B5563)),
          fontSize: 12,
          height: 1.5,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: catalog.map((a) {
        final unlocked = player.achievements.containsKey(a.id);
        final lockedLabel = a.comingSoon ? 'SOON' : '???';
        return GestureDetector(
          onTap: unlocked ? () => _showFeaturedPicker(context, player) : null,
          child: SizedBox(
            width: 70,
            child: Column(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 10.0,
                    backgroundColor: unlocked
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.outline.withValues(alpha: 0.2),
                    borderColor: unlocked
                        ? cs.primary.withValues(alpha: 0.4)
                        : cs.outline.withValues(alpha: 0.4),
                    blurRadius: 8.0,
                    child: Center(
                      child: Icon(
                        unlocked ? a.icon : (a.comingSoon ? Icons.lock_clock : Icons.help_outline),
                        color: unlocked
                            ? cs.secondary
                            : (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.2) : const Color(0xFF4B5563)),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked ? a.name : lockedLabel,
                  style: TextStyle(
                    color: unlocked
                        ? (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.7) : const Color(0xFF4B5563))
                        : (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.2) : const Color(0xFF4B5563)),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  void _showEditNameDialog(BuildContext context, PlayerData player) {
    final cs = Theme.of(context).colorScheme;
    final currentName = player.name;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outline),
        ),
        title: Text(
          'EDIT ALIAS',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter new alias...',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primary),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final updated = player.copyWith(name: newName);
                gameService.updatePlayer(updated);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'SAVE',
              style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
