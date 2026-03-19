import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../models/achievement.dart';
import '../theme/night_guild_background.dart';
import 'settings_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, cs),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarCard(
                          context,
                          cs,
                          player,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'DAO PATHS',
                          _buildClassTracks(cs, player),
                          cs,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'DAO PROGRESS',
                          _buildCoreStats(cs, player),
                          cs,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'SPIRITUAL ARTIFACTS',
                          _buildArsenal(cs, player),
                          cs,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          '★  FEATURED MERIT',
                          _buildFeaturedAchievement(context, cs, player),
                          cs,
                        ),
                        const SizedBox(height: 16),
                        _buildSection('HEAVENLY MERITS', _buildBadges(context, cs, player), cs),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'IDENTITY',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.5) : const Color(0xFF4B5563)),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: decoration,
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
              _chip('Lv. $level', cs),
              const SizedBox(width: 8),
              _chip(mainClass, cs),
            ],
          ),
        ],
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline, width: 1),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildClassTracks(ColorScheme cs, PlayerData player) {
    final mainXp = player.pathQi[player.mainPath] ?? 0.0;
    final mainMax = player.pathMaxQi(player.mainPath);
    final mainLv = player.pathLevel[player.mainPath] ?? 1;

    final sideXp = player.pathQi[player.sidePath] ?? 0.0;
    final sideMax = player.pathMaxQi(player.sidePath);
    final sideLv = player.pathLevel[player.sidePath] ?? 1;

    return Column(
      children: [
        _classTrackRow(
          player.mainPath,
          true,
          mainMax > 0 ? mainXp / mainMax : 0.0,
          mainLv,
          cs,
        ),
        const SizedBox(height: 12),
        _classTrackRow(
          player.sidePath,
          false,
          sideMax > 0 ? sideXp / sideMax : 0.0,
          sideLv,
          cs,
        ),
      ],
    );
  }

  Widget _classTrackRow(
    String className,
    bool isMain,
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
              Row(
                children: [
                  Text(
                    className,
                    style: TextStyle(
                      color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.7) : const Color(0xFF4B5563)),
                      fontSize: 13,
                    ),
                  ),
                  if (isMain) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'MAIN',
                        style: TextStyle(
                          color: cs.secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
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

  Widget _buildCoreStats(ColorScheme cs, PlayerData player) {
    final devLevel = player.pathLevel[player.mainPath] ?? 1;
    final secLevel = player.pathLevel[player.sidePath] ?? 1;

    final problemSolving = (devLevel * 10 / 5).round().clamp(0, 10);
    final recon = (secLevel * 10 / 5).round().clamp(0, 10);
    final exploitation = (secLevel * 10 / 5).round().clamp(0, 10);

    return Column(
      children: [
        _statRow('Problem Solving', problemSolving, 10, cs),
        const SizedBox(height: 10),
        _statRow('Recon', recon, 10, cs),
        const SizedBox(height: 10),
        _statRow('Exploitation', exploitation, 10, cs),
      ],
    );
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: unlocked
                          ? cs.primary.withValues(alpha: 0.4)
                          : cs.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    unlocked ? a.icon : (a.comingSoon ? Icons.lock_clock : Icons.help_outline),
                    color: unlocked
                        ? cs.secondary
                        : (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.2) : const Color(0xFF4B5563)),
                    size: 22,
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
