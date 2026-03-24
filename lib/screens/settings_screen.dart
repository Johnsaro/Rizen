import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../main.dart';
import '../app_state.dart';
import '../models/app_config.dart';
import '../models/player_data.dart';
import '../services/guest_session.dart';
import '../services/supabase_service.dart';
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
                    const SizedBox(height: 12),
                    _buildThemeToggle(cs),
                    const SizedBox(height: 32),
                    _sectionLabel('FUTURE REVELATIONS', cs),
                    const SizedBox(height: 12),
                    _buildComingSoon(cs),
                    const SizedBox(height: 40),
                    if (GuestSession.isActive) _buildGuestInfo(cs),
                    if (GuestSession.isActive) const SizedBox(height: 12),
                    _buildSignOut(cs),
                    const SizedBox(height: 32),
                    _sectionLabel('SYSTEM DEBUG', cs),
                    const SizedBox(height: 12),
                    _buildTimeDebugRow(cs),
                    const SizedBox(height: 12),
                    _buildDebugRow(cs),
                    const SizedBox(height: 12),
                    _buildDebugBossFight(cs),
                    const SizedBox(height: 12),
                    _buildDebugAddRep(cs),
                    const SizedBox(height: 40),
                    _buildCheckForUpdates(cs),
                    const SizedBox(height: 16),
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

  Widget _buildTimeDebugRow(ColorScheme cs) {
    return ValueListenableBuilder<TimeRevelation>(
      valueListenable: timeRevelationNotifier,
      builder: (context, current, _) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline, width: 1),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _timeDebugOption('Dawn', TimeRevelation.dawn, current, cs),
                _timeDebugOption('Morn', TimeRevelation.morning, current, cs),
                _timeDebugOption('Eve', TimeRevelation.evening, current, cs),
                _timeDebugOption('Auto', TimeRevelation.auto, current, cs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _timeDebugOption(String label, TimeRevelation mode, TimeRevelation current, ColorScheme cs) {
    final selected = current == mode;
    return GestureDetector(
      onTap: () => timeRevelationNotifier.value = mode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : cs.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
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

  void _resetNotifiers() {
    playerNotifier.value = PlayerData.empty;
    questNotifier.value = [];
    guildBoardNotifier.value = [];
    checkedInNotifier.value = false;
    notificationsNotifier.value = [];
    prNotifier.value = [];
  }

  void _navigateToAuth({bool migrateFromGuest = false}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(migrateFromGuest: migrateFromGuest),
      ),
      (route) => false,
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
    _resetNotifiers();
    if (!mounted) return;
    _navigateToAuth();
  }

  Future<void> _clearGuestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dcs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: dcs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: dcs.outline),
          ),
          title: Text(
            'Clear Guest Data?',
            style: TextStyle(color: dcs.onSurface, fontSize: 16),
          ),
          content: Text(
            'All local progress will be permanently deleted. This cannot be undone.',
            style: TextStyle(
              color: dcs.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await GuestSession.clear();
    _resetNotifiers();
    if (!mounted) return;
    _navigateToAuth();
  }

  Widget _buildGuestInfo(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Guest data is stored locally and will be lost on uninstall. '
        'Create an account to secure your progress.',
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.5),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildSignOut(ColorScheme cs) {
    if (GuestSession.isActive) {
      return Column(
        children: [
          GestureDetector(
            onTap: () => _navigateToAuth(migrateFromGuest: true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'CREATE ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _clearGuestData,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'CLEAR GUEST DATA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
        final updated = prev.copyWith(spiritStones: prev.spiritStones + 2000);
        // Set notifier directly so UI reflects immediately regardless of Supabase
        playerNotifier.value = updated;
        try {
          await gameService.updatePlayer(updated);
        } catch (_) {
          // Best-effort persist — debug mode doesn't need Supabase to work
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('[DEBUG] +2000 Stones added (${updated.spiritStones} total)')),
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

  bool _isCheckingUpdate = false;

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);

    try {
      final config = await SupabaseService.loadAppConfig();
      currentAppConfig = config;

      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      final hasUpdate = compareVersions(appVersion, config.latestVersion) < 0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outline),
          ),
          title: Row(
            children: [
              Icon(
                hasUpdate ? Icons.system_update : Icons.check_circle_outline,
                color: hasUpdate ? cs.primary : Colors.green,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                hasUpdate ? 'Update Available' : 'Up to Date',
                style: TextStyle(color: cs.onSurface, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            hasUpdate
                ? 'Version ${config.latestVersion} is available.\nYou have v$appVersion.'
                : 'You are running the latest version (v$appVersion).',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(hasUpdate ? 'LATER' : 'OK'),
            ),
            if (hasUpdate && config.downloadUrl.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  launchUrl(
                    Uri.parse(config.downloadUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('DOWNLOAD'),
              ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Widget _buildCheckForUpdates(ColorScheme cs) {
    return GestureDetector(
      onTap: _isCheckingUpdate ? null : _checkForUpdates,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.system_update, color: cs.onSurface.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Text(
              'Check for Updates',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
            ),
            const Spacer(),
            if (_isCheckingUpdate)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              )
            else
              Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildVersion(ColorScheme cs) {
    return Center(
      child: Text(
        'Cultivation System v$appVersion',
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
