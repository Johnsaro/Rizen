import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart' show PlayerData, CultivationRealms;
import '../widgets/glass_card.dart';
import '../models/game_notification.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'notifications_screen.dart';
import 'inventory_screen.dart';
import 'merchant_log/merchant_log_screen.dart';
import 'onboarding_screen.dart' show pathIconFor;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // Pulsing aura animation
  late final AnimationController _auraController;
  late final Animation<double> _auraScale;

  // Immovable badge glow pulse (2.5s)
  late final AnimationController _immovablePulseController;
  late final Animation<double> _immovablePulse;

  // Qi Deviation red pulse (3s, opacity 0.6–1.0)
  late final AnimationController _deviationPulseController;
  late final Animation<double> _deviationPulse;

  // Countdown timer
  Timer? _countdownTimer;
  Duration _timeUntilMidnight = Duration.zero;

  late final AnimationController _ringRotationController;

  @override
  void initState() {
    super.initState();

    _ringRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Subtle aura pulse: 1.0 → 1.04 → 1.0 every 2.5 s
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _auraScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    // Immovable badge glow: scale 1.0 → 1.06 every 2.5s (started on demand)
    _immovablePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _immovablePulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _immovablePulseController, curve: Curves.easeInOut),
    );

    // Qi Deviation red pulse: opacity 0.6 → 1.0 every 3s (started on demand)
    _deviationPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _deviationPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _deviationPulseController, curve: Curves.easeInOut),
    );

    // Start/stop pulse controllers based on player state
    playerNotifier.addListener(_syncPulseControllers);
    _syncPulseControllers();

    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _updateCountdown());
      // Auto-clear expired Qi Deviation mid-session
      final p = playerNotifier.value;
      if (p.qiDeviationActive && !p.isQiDeviationActive) {
        final cleared = p.clearQiDeviation();
        playerNotifier.value = cleared;
        // Persist so it doesn't resurrect on next app open
        gameService.updatePlayer(cleared);
      }
    });
  }

  void _syncPulseControllers() {
    final player = playerNotifier.value;
    // Immovable glow
    if (player.daoHeartState == 'Immovable') {
      if (!_immovablePulseController.isAnimating) {
        _immovablePulseController.repeat(reverse: true);
      }
    } else {
      if (_immovablePulseController.isAnimating) {
        _immovablePulseController.stop();
        _immovablePulseController.reset();
      }
    }
    // Deviation red pulse
    if (player.isQiDeviationActive) {
      if (!_deviationPulseController.isAnimating) {
        _deviationPulseController.repeat(reverse: true);
      }
    } else {
      if (_deviationPulseController.isAnimating) {
        _deviationPulseController.stop();
        _deviationPulseController.value = 1.0; // full opacity when not pulsing
      }
    }
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final midnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _timeUntilMidnight = midnight.difference(now);
  }

  @override
  void dispose() {
    _ringRotationController.dispose();
    playerNotifier.removeListener(_syncPulseControllers);
    _auraController.dispose();
    _immovablePulseController.dispose();
    _deviationPulseController.dispose();
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
                  if (player.isQiDeviationActive)
                    _buildQiDeviationWarning(cs, player),
                ],
              ),
            ),
            // Pill badges row
            ValueListenableBuilder<PlayerData>(
              valueListenable: playerNotifier,
              builder: (_, player, _) => _buildPillBadges(cs, player),
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
            child: Icon(Icons.density_medium, color: cs.onSurface, size: 26),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                ),
                child: Icon(Icons.inventory_2_outlined, color: cs.onSurface, size: 24),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                ),
                child: Icon(Icons.store_mall_directory_outlined,
                    color: cs.onSurface, size: 24),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MerchantLogScreen()),
                ),
                child: Icon(Icons.receipt_long_outlined,
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
                      Icon(Icons.notifications_none,
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
                  CultivationRealms.shortDisplayFor(player.level),
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
          const SizedBox(height: 2),
          Text(
            '${CultivationRealms.subStageFor(CultivationRealms.rankFor(player.level))} Stage',
            style: GoogleFonts.jetBrainsMono(
              color: cs.onSurface.withValues(alpha: 0.35),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dao Heart + Talismans row ────────────────────────────────

  // ── Dao Heart state visual config ──────────────────────
  static const _daoHeartColors = <String, Color>{
    'Wavering':   Color(0xFF9590A8),
    'Steady':     Color(0xFFFB923C),
    'Firm':       Color(0xFFF59E0B),
    'Unyielding': Color(0xFFFBBF24),
    'Immovable':  Color(0xFF00C9A7),
  };

  static IconData _daoHeartIcon(String state) {
    return (state == 'Unyielding' || state == 'Immovable')
        ? Icons.whatshot
        : Icons.local_fire_department;
  }

  Widget _buildStreakShieldsRow(ColorScheme cs, PlayerData player) {
    const shieldColor = Color(0xFF60A5FA);
    final stateColor = _daoHeartColors[player.daoHeartState] ?? const Color(0xFF9590A8);
    final bonus = PlayerData.qiBonusForStreak(player.daoHeartStreak);
    final bonusPercent = (bonus * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          // Dao Heart badge — rich version (Immovable gets pulsing glow)
          AnimatedBuilder(
            animation: _immovablePulseController,
            builder: (context, child) {
              final isImmovable = player.daoHeartState == 'Immovable';
              return Transform.scale(
                scale: isImmovable ? _immovablePulse.value : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isImmovable
                        ? [BoxShadow(
                            color: stateColor.withValues(alpha: 0.3 * _immovablePulse.value),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )]
                        : null,
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    borderRadius: 12.0,
                    backgroundColor: stateColor.withValues(alpha: 0.1),
                    borderColor: stateColor.withValues(alpha: 0.5),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_daoHeartIcon(player.daoHeartState), color: stateColor, size: 14),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.daoHeartState.toUpperCase(),
                            style: GoogleFonts.cinzel(
                              color: stateColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${player.daoHeartStreak}-day',
                            style: GoogleFonts.jetBrainsMono(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (bonusPercent > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '+$bonusPercent%',
                          style: GoogleFonts.jetBrainsMono(
                            color: stateColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ),
              );
            },
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

  // ── Qi Deviation Warning ───────────────────────────────

  Widget _buildQiDeviationWarning(ColorScheme cs, PlayerData player) {
    const devColor = Color(0xFFEF4444);
    // Compute time remaining
    String remaining = '';
    final expiry = DateTime.tryParse(player.qiDeviationExpiry);
    if (expiry != null) {
      final diff = expiry.difference(DateTime.now());
      if (diff.inHours >= 1) {
        remaining = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
      } else if (diff.inMinutes > 0) {
        remaining = '${diff.inMinutes}m left';
      } else {
        remaining = 'expiring...';
      }
    }

    return AnimatedBuilder(
      animation: _deviationPulseController,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        child: Opacity(
          opacity: _deviationPulse.value,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: 12.0,
            backgroundColor: devColor.withValues(alpha: 0.15),
            borderColor: devColor.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: devColor, size: 13),
                const SizedBox(width: 4),
                Text(
                  'QI DEVIATION',
                  style: GoogleFonts.cinzel(
                    color: devColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${player.qiDeviationTrials}/3 trials',
                  style: GoogleFonts.jetBrainsMono(
                    color: devColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
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
          ),
        ),
      ),
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

  IconData _iconForClass(String title) => pathIconFor(title);

  Widget _buildCharacterAura(ColorScheme cs, PlayerData player) {
    final classIcon = _iconForClass(player.mainPath);
    final qiPercent = player.maxQi > 0 ? player.qi / player.maxQi : 0.0;
    
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
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.25),
                    cs.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Dao Path Ring (Progressive filling based on Qi)
            SizedBox(
              width: 210,
              height: 210,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: qiPercent),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.0,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary.withValues(alpha: 0.8)),
                ),
              ),
            ),
            
            // Inner Core Rotation
            RotationTransition(
              turns: _ringRotationController,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 1.0),
                ),
                child: Stack(
                  children: [
                    // Orbital Particles
                    Align(
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.star, size: 8, color: cs.primary),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.star, size: 8, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ),

            // The Spiritual Core Glass Plate
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surface.withValues(alpha: 0.6),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            classIcon,
                            size: 64,
                            color: cs.primary.withValues(alpha: 0.3),
                            shadows: [
                              Shadow(color: cs.primary.withValues(alpha: 0.5), blurRadius: 16),
                            ],
                          ),
                          Icon(
                            classIcon,
                            size: 64,
                            color: cs.primary.withValues(alpha: 0.95),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Ancient bracket accents
            Positioned(
              left: 15,
              child: Text(
                '「',
                style: GoogleFonts.cinzel(
                  color: cs.primary.withValues(alpha: 0.3),
                  fontSize: 70,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            Positioned(
              right: 15,
              child: Text(
                '」',
                style: GoogleFonts.cinzel(
                  color: cs.primary.withValues(alpha: 0.3),
                  fontSize: 70,
                  fontWeight: FontWeight.w100,
                ),
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
              border: Border.all(
                color: cs.brightness == Brightness.dark
                    ? cs.outline
                    : cs.onSurface.withValues(alpha: 0.12),
                width: 1,
              ),
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

    final mainXp = player.pathQi[player.mainPath] ?? 0.0;
    final mainMax = player.pathMaxQi(player.mainPath);

    final mainLv = player.pathLevel[player.mainPath] ?? 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: _buildClassTrack(
        label: mainLabel,
        progress: mainMax > 0 ? mainXp / mainMax : 0.0,
        level: mainLv,
        icon: _classIcon(player.mainPath),
        cs: cs,
      ),
    );
  }

  IconData _classIcon(String className) => pathIconFor(className);

  Widget _buildClassTrack({
    required String label,
    required double progress,
    required int level,
    required IconData icon,
    required ColorScheme cs,
  }) {
    final trackColor = cs.primary;
    final trackColorText = cs.brightness == Brightness.dark ? trackColor : cs.onSurface;
    final borderColor = cs.brightness == Brightness.dark 
        ? trackColor.withValues(alpha: 0.3)
        : cs.onSurface.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.brightness == Brightness.dark
            ? Colors.transparent
            : cs.surface,
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
