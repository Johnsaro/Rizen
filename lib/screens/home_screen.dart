import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../models/game_notification.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'notifications_screen.dart';
import 'inventory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Pulsing aura animation
  late final AnimationController _auraController;
  late final Animation<double> _auraScale;

  // Countdown timer
  Timer? _countdownTimer;
  Duration _timeUntilMidnight = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Subtle aura pulse: 1.0 → 1.04 → 1.0 every 2.5 s
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _auraScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _updateCountdown());
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final midnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _timeUntilMidnight = midnight.difference(now);
  }

  @override
  void dispose() {
    _auraController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    return '${d.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, cs),
            ValueListenableBuilder<PlayerData>(
              valueListenable: playerNotifier,
              builder: (_, player, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlayerInfo(cs, player),
                  _buildStreakShieldsRow(cs, player),
                ],
              ),
            ),
            // Pill badges row
            ValueListenableBuilder<PlayerData>(
              valueListenable: playerNotifier,
              builder: (_, player, __) => _buildPillBadges(cs, player),
            ),
            // Character aura + HP bar
            Expanded(
              child: ValueListenableBuilder<PlayerData>(
                valueListenable: playerNotifier,
                builder: (_, player, _) => _buildCharacterSection(cs, player),
              ),
            ),
            // Daily countdown
            _buildCountdownBanner(cs),
            // Qi bar
            ValueListenableBuilder<PlayerData>(
              valueListenable: playerNotifier,
              builder: (_, player, _) =>
                  _buildXPSection(cs, player.qi, player.maxQi),
            ),
            // Dao Path tracks
            ValueListenableBuilder<PlayerData>(
              valueListenable: playerNotifier,
              builder: (_, player, _) => _buildClassTracks(cs, player),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Icon(Icons.menu, color: cs.onSurface, size: 26),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                ),
                child: Icon(Icons.backpack_outlined, color: cs.onSurface, size: 24),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                ),
                child: Icon(Icons.storefront,
                    color: cs.onSurface, size: 24),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: ValueListenableBuilder<List<GameNotification>>(
                  valueListenable: notificationsNotifier,
                  builder: (_, notifications, _) => Stack(
                    children: [
                      Icon(Icons.auto_awesome_outlined,
                          color: cs.onSurface, size: 26),
                      if (notifications.isNotEmpty)
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Player name / level / Dao Path ─────────────────────────

  Widget _buildPlayerInfo(ColorScheme cs, PlayerData player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                player.name,
                style: GoogleFonts.cinzel(
                  color: cs.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  'Realm Lv. ${player.level}',
                  style: GoogleFonts.jetBrainsMono(
                    color: cs.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            player.mainPath,
            style: TextStyle(
              color: cs.brightness == Brightness.dark ? cs.primary : cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dao Heart + Talismans row ────────────────────────────────

  Widget _buildStreakShieldsRow(ColorScheme cs, PlayerData player) {
    const streakColor = Color(0xFFFB923C); // amber
    const shieldColor = Color(0xFF60A5FA); // talisman blue

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          // Dao Heart
          _buildStatBadge(
            icon: Icons.local_fire_department,
            iconColor: streakColor,
            label: '${player.daoHeartStreak}-day heart',
            cs: cs,
          ),
          const SizedBox(width: 12),
          // Talismans
          _buildStatBadge(
            icon: Icons.auto_awesome,
            iconColor: shieldColor,
            label: '${player.talismans} talisman${player.talismans == 1 ? '' : 's'}',
            cs: cs,
          ),
          const SizedBox(width: 12),
          // Spirit Stones
          _buildStatBadge(
            icon: Icons.stars,
            iconColor: const Color(0xFFFBBF24),
            label: '${player.spiritStones} stones',
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required ColorScheme cs,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.6) : const Color(0xFF4B5563)),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Active Pill Badges ──────────────────────────────────

  Widget _buildPillBadges(ColorScheme cs, PlayerData player) {
    final activePillEntries = player.activePills.entries
        .where((e) => player.isPillActive(e.key))
        .toList();

    if (activePillEntries.isEmpty) return const SizedBox(height: 6);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: activePillEntries.map((e) {
            final expiry = _pillExpiry(e.key, e.value);
            return _buildPillBadge(cs, e.key, expiry);
          }).toList(),
        ),
      ),
    );
  }

  String _pillExpiry(String name, String value) {
    try {
      final iso = value.startsWith('next_quest')
          ? value.split('|').last
          : value;
      final expires = DateTime.parse(iso);
      final diff = expires.difference(DateTime.now());
      if (name == 'Qi Surge Pill') return 'next trial';
      if (diff.inHours >= 1) return '${diff.inHours}h${diff.inMinutes.remainder(60)}m';
      return '${diff.inMinutes}m';
    } catch (_) {
      return '';
    }
  }

  Widget _buildPillBadge(ColorScheme cs, String name, String timeLabel) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: cs.tertiary, size: 12),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: cs.tertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              timeLabel,
              style: TextStyle(
                color: cs.tertiary.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Character aura + HP bar ─────────────────────────────

  Widget _buildCharacterSection(ColorScheme cs, PlayerData player) {
    final hpRatio = player.maxHp > 0 ? player.hp / player.maxHp : 1.0;
    final hpColor = hpRatio > 0.5
        ? cs.primary
        : hpRatio > 0.25
            ? const Color(0xFFFB923C)
            : const Color(0xFFFF3131);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildCharacterAura(cs, player)),
        // HP bar beneath aura
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: hpColor, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'VITALITY',
                        style: GoogleFonts.cinzel(
                          color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)),
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${player.hp} / ${player.maxHp}',
                    style: GoogleFonts.jetBrainsMono(
                      color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: hpRatio),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: cs.outline,
                    valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconForClass(String title) {
    if (title.contains('Shadow')) return Icons.security;
    if (title.contains('Formation')) return Icons.code;
    if (title.contains('Artifact')) return Icons.settings_input_component;
    if (title.contains('Realm')) return Icons.sports_esports;
    if (title.contains('Network')) return Icons.hub;
    if (title.contains('Data')) return Icons.storage;
    return Icons.auto_awesome;
  }

  Widget _buildCharacterAura(ColorScheme cs, PlayerData player) {
    final classIcon = _iconForClass(player.mainPath);

    return Center(
      child: AnimatedBuilder(
        animation: _auraScale,
        builder: (_, child) => Transform.scale(
          scale: _auraScale.value,
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient outer glow
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.15),
                    cs.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Ink-ring 1
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1),
              ),
            ),
            // Ink-ring 2 (Inner solid)
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary.withValues(alpha: 0.8), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Dark hollow center
            Container(
              width: 166,
              height: 166,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surface.withValues(alpha: 0.9), 
              ),
            ),
            // Spiritual Path Crest
            Icon(
              classIcon,
              size: 64,
              color: cs.primary.withValues(alpha: 0.9),
            ),
            // Aura blur layer underneath
            Icon(
              classIcon,
              size: 64,
              color: cs.primary.withValues(alpha: 0.5),
              shadows: [
                Shadow(color: cs.primary, blurRadius: 30),
                Shadow(color: cs.primary, blurRadius: 60),
              ],
            ),
            // Ancient bracket accents
            Positioned(
              left: 30,
              child: Text(
                '「',
                style: GoogleFonts.cinzel(
                  color: cs.primary.withValues(alpha: 0.4),
                  fontSize: 80,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            Positioned(
              right: 30,
              child: Text(
                '」',
                style: GoogleFonts.cinzel(
                  color: cs.primary.withValues(alpha: 0.4),
                  fontSize: 80,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            // Mini runes orbiting the crest
            Positioned(
              left: 50,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: Icon(Icons.bolt,
                    color: cs.primary, size: 16),
              ),
            ),
            Positioned(
              right: 50,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: Icon(Icons.auto_awesome,
                    color: cs.primary, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Daily reset banner ──────────────────────────────

  Widget _buildCountdownBanner(ColorScheme cs) {
    final urgency = _timeUntilMidnight.inHours < 3;
    final color = urgency
        ? const Color(0xFFFB923C)
        : (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.35) : const Color(0xFF4B5563));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            _formatCountdown(_timeUntilMidnight),
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'celestial reset',
            style: TextStyle(
              color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.25) : const Color(0xFF4B5563)),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Qi Section ──────────────────────────────────────────

  Widget _buildXPSection(
      ColorScheme cs, double currentXP, double maxXP) {
    final double progress = maxXP > 0 ? currentXP / maxXP : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QI FLOW',
                style: GoogleFonts.cinzel(
                  color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentXP.toInt()} / ${maxXP.toInt()}',
                style: GoogleFonts.jetBrainsMono(
                  color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dao Path Tracks ────────────────────────────────────────

  Widget _buildClassTracks(ColorScheme cs, PlayerData player) {
    final mw = player.mainPath.split(' ').first;
    final mainLabel =
        (mw.length >= 3 ? mw.substring(0, 3) : mw).toUpperCase();
    final sw = player.sidePath.split(' ').first;
    final sideLabel =
        (sw.length >= 3 ? sw.substring(0, 3) : sw).toUpperCase();

    final mainXp = player.pathQi[player.mainPath] ?? 0.0;
    final mainMax = player.pathMaxQi(player.mainPath);
    final sideXp = player.pathQi[player.sidePath] ?? 0.0;
    final sideMax = player.pathMaxQi(player.sidePath);

    final mainLv = player.pathLevel[player.mainPath] ?? 1;
    final sideLv = player.pathLevel[player.sidePath] ?? 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildClassTrack(
              label: mainLabel,
              progress: mainMax > 0 ? mainXp / mainMax : 0.0,
              level: mainLv,
              isMain: true,
              icon: _classIcon(player.mainPath),
              cs: cs,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildClassTrack(
              label: sideLabel,
              progress: sideMax > 0 ? sideXp / sideMax : 0.0,
              level: sideLv,
              isMain: false,
              icon: _classIcon(player.sidePath),
              cs: cs,
            ),
          ),
        ],
      ),
    );
  }

  IconData _classIcon(String className) {
    final lower = className.toLowerCase();
    if (lower.contains('sec') || lower.contains('analyst')) {
      return Icons.security;
    } else if (lower.contains('dev') || lower.contains('developer')) {
      return Icons.code;
    } else if (lower.contains('net') || lower.contains('network')) {
      return Icons.hub;
    } else if (lower.contains('data')) {
      return Icons.storage;
    }
    return Icons.auto_awesome;
  }

  Widget _buildClassTrack({
    required String label,
    required double progress,
    required int level,
    required bool isMain,
    required IconData icon,
    required ColorScheme cs,
  }) {
    // Primary path gets jade accent, secondary gets violet
    final trackColor = isMain ? cs.primary : cs.tertiary;
    final trackColorText = cs.brightness == Brightness.dark ? trackColor : cs.onSurface;
    final borderColor = cs.brightness == Brightness.dark 
        ? trackColor.withValues(alpha: 0.3)
        : cs.onSurface.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: trackColor, size: 12),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.cinzel(
                  color: trackColorText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                'Lv.$level',
                style: GoogleFonts.jetBrainsMono(
                  color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.35) : const Color(0xFF4B5563)),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cs.outline,
              valueColor: AlwaysStoppedAnimation<Color>(trackColor),
            ),
          ),
        ],
      ),
    );
  }
}
