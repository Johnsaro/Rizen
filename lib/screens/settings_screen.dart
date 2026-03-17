import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../theme/night_guild_background.dart';
import 'auth_screen.dart';
import 'combat/combat_screen.dart';
import 'combat/tier_two_combat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get _isDark => themeNotifier.value == ThemeMode.dark;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('VISUAL DAO', cs),
                    const SizedBox(height: 8),
                    _buildThemeToggle(cs),
                    const SizedBox(height: 24),
                    _sectionLabel('FUTURE REVELATIONS', cs),
                    const SizedBox(height: 8),
                    _buildComingSoon(cs),
                    const SizedBox(height: 32),
                    _buildSignOut(cs),
                    const SizedBox(height: 24),
                    _sectionLabel('SYSTEM DEBUG', cs),
                    const SizedBox(height: 8),
                    _buildDebugRow(cs),
                    const SizedBox(height: 8),
                    _buildDebugBossFight(cs),
                    const SizedBox(height: 8),
                    _buildDebugAddRep(cs),
                    const SizedBox(height: 32),
                    _buildVersion(cs),
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

  Widget _buildTopBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, color: cs.onSurface.withValues(alpha: 0.6), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'SYSTEM SETTINGS',
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

  Widget _buildThemeToggle(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Row(
        children: [
          _themeOption(
            label: 'Void',
            icon: Icons.dark_mode_outlined,
            selected: _isDark,
            cs: cs,
            onTap: () {
              setState(() {});
              themeNotifier.value = ThemeMode.dark;
            },
          ),
          _themeOption(
            label: 'Mist',
            icon: Icons.light_mode_outlined,
            selected: !_isDark,
            cs: cs,
            onTap: () {
              setState(() {});
              themeNotifier.value = ThemeMode.light;
            },
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.black : cs.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronization break failed — check your connection.')),
        );
      }
      return;
    }
    playerNotifier.value = PlayerData.empty;
    questNotifier.value = [];
    guildBoardNotifier.value = [];
    checkedInNotifier.value = false;
    notificationsNotifier.value = [];
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Widget _buildSignOut(ColorScheme cs) {
    return GestureDetector(
      onTap: _signOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'SEVER CONNECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDebugRow(ColorScheme cs) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CombatScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.sports_martial_arts, color: cs.onSurface.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Text(
              '[DEBUG] Enlightenment Trial',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugBossFight(ColorScheme cs) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TierTwoCombatScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: cs.error.withValues(alpha: 0.6), size: 20),
            const SizedBox(width: 12),
            Text(
              '[DEBUG] Ascension Trial',
              style: TextStyle(color: cs.error.withValues(alpha: 0.6), fontSize: 13),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugAddRep(ColorScheme cs) {
    return GestureDetector(
      onTap: () async {
        final prev = playerNotifier.value;
        await gameService.updatePlayer(prev.copyWith(rep: prev.rep + 2000));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('[DEBUG] +2000 Stones added')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.stars, color: cs.onSurface.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Text(
              '[DEBUG] +2000 Stones',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildVersion(ColorScheme cs) {
    return Center(
      child: Text(
        'Cultivation System v2.0.0',
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.2),
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildComingSoon(ColorScheme cs) {
    final items = [
      (Icons.notifications_outlined, 'Divine Sense Whispers'),
      (Icons.lock_outline, 'Dao Privacy'),
      (Icons.account_circle_outlined, 'Identity Record'),
      (Icons.folder_outlined, 'Realm Watcher'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(item.$1, color: cs.onSurface.withValues(alpha: 0.3), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'soon',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, color: cs.outline),
            ],
          );
        }),
      ),
    );
  }
}
