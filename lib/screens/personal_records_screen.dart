import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart' show PlayerData, CultivationRealms;
import '../theme/night_guild_background.dart';

class PersonalRecordsScreen extends StatelessWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, cs),
              Expanded(
                child: ValueListenableBuilder<PlayerData>(
                  valueListenable: playerNotifier,
                  builder: (_, player, _) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('CULTIVATION BASE', _buildPersonalBests(cs, player), cs),
                        const SizedBox(height: 16),
                        _buildSection('DAO PROGRESS', _buildStatsOverview(cs, player), cs),
                        const SizedBox(height: 16),
                        _buildSection('PATH OF ASCENSION', _buildMilestones(cs, player), cs),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios,
                color: cs.onSurface.withValues(alpha: 0.5), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'CULTIVATION ARCHIVE',
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
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
          style: GoogleFonts.cinzel(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildPersonalBests(ColorScheme cs, PlayerData player) {
    return Column(
      children: [
        _bestCard(
          cs,
          icon: Icons.local_fire_department,
          iconColor: const Color(0xFFFF6B35),
          label: 'Dao Heart Stability',
          value: '${player.daoHeartStreak} days',
        ),
        const SizedBox(height: 8),
        _bestCard(
          cs,
          icon: Icons.stars,
          iconColor: const Color(0xFFFFD700),
          label: 'Total Stones Earned',
          value: _formatNumber(player.spiritStones),
        ),
        const SizedBox(height: 8),
        _bestCard(
          cs,
          icon: Icons.task_alt,
          iconColor: Colors.green,
          label: 'Trials Overcome',
          value: '${player.trialsCompleted}',
        ),
        const SizedBox(height: 8),
        _bestCard(
          cs,
          icon: Icons.bolt,
          iconColor: Colors.redAccent,
          label: 'Beasts Vanquished',
          value: '${player.monstersKilled}',
        ),
      ],
    );
  }

  Widget _bestCard(
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: cs.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ColorScheme cs, PlayerData player) {
    final mainLv = player.pathLevel[player.mainPath] ?? 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Column(
        children: [
          _overviewRow(cs, 'Cultivation', CultivationRealms.shortDisplayFor(player.level)),
          const SizedBox(height: 10),
          _overviewRow(cs, _displayPathName(player.mainPath), 'Lv $mainLv', badge: 'PRIMARY'),
          const SizedBox(height: 10),
          _overviewRow(cs, 'Heavenly Merits', '${player.achievements.length}'),
        ],
      ),
    );
  }

  Widget _overviewRow(ColorScheme cs, String label, String value, {String? badge}) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: cs.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: cs.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestones(ColorScheme cs, PlayerData player) {
    final milestones = <_Milestone>[];

    if (player.trialsCompleted >= 1) {
      milestones.add(_Milestone('First Trial Realized', Icons.task_alt));
    }
    if (player.trialsCompleted >= 10) {
      milestones.add(_Milestone('10 Trials Completed', Icons.task_alt));
    }
    if (player.trialsCompleted >= 50) {
      milestones.add(_Milestone('50 Trials Overcome', Icons.task_alt));
    }
    if (player.trialsCompleted >= 100) {
      milestones.add(_Milestone('Centenary Trial Milestone', Icons.task_alt));
    }
    if (player.monstersKilled >= 1) {
      milestones.add(_Milestone('First Beast Subdued', Icons.bolt));
    }
    if (player.monstersKilled >= 10) {
      milestones.add(_Milestone('Beast Slayer Insight', Icons.bolt));
    }
    if (player.level >= 5) {
      milestones.add(_Milestone('Reached Realm Lv 5', Icons.upgrade));
    }
    if (player.level >= 10) {
      milestones.add(_Milestone('Reached Realm Lv 10', Icons.upgrade));
    }
    if (player.level >= 20) {
      milestones.add(_Milestone('Advanced Cultivator (Lv 20)', Icons.upgrade));
    }
    if (player.achievements.isNotEmpty) {
      milestones.add(_Milestone('First Merit Awarded', Icons.auto_awesome));
    }
    if (player.achievements.length >= 5) {
      milestones.add(_Milestone('Collector of Heavenly Merits', Icons.auto_awesome));
    }

    if (milestones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Text(
          'The path is long. Complete trials and elevate your realm to record milestones.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.35),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < milestones.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(milestones[i].icon, color: cs.secondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  milestones[i].label,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (i < milestones.length - 1) ...[
              Padding(
                padding: const EdgeInsets.only(left: 3.5),
                child: Container(
                  width: 1,
                  height: 16,
                  color: cs.primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return '$n';
  }

  String _displayPathName(String className) => className;
}

class _Milestone {
  final String label;
  final IconData icon;
  const _Milestone(this.label, this.icon);
}
