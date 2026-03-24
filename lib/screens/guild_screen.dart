import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';
import '../models/quest.dart';
import '../theme/rank_colors.dart' as rc;
import 'guild_master_screen.dart';
import 'library/library_screen.dart';
import 'personal_records_screen.dart';
import '../widgets/check_in_overlay.dart';
import '../widgets/nag_prompt.dart';
import '../theme/night_guild_background.dart';

class GuildScreen extends StatefulWidget {
  const GuildScreen({super.key});

  @override
  State<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends State<GuildScreen> {
  Timer? _clockTimer;
  String _timeStr = _formatTime(DateTime.now());
  bool _isCheckingIn = false;

  static String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _isOpen {
    final h = DateTime.now().hour;
    return h >= 8 && h < 23;
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _timeStr = _formatTime(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;

      await gameService.checkIn();

      if (mounted && checkedInNotifier.value) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (ctx, a1, a2) => CheckInOverlay(
            onComplete: () => Navigator.of(ctx).pop(),
          ),
        );
        NagPrompt.maybeShow(context);
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, cs),
              Expanded(
                child: _isOpen
                    ? _buildGuildOpen(context, cs)
                    : _buildGuildClosed(cs),
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
          Text(
            'SECT HALL',
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _isOpen
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isOpen
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.red.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              _isOpen ? 'ACCESSIBLE' : 'SEALED',
              style: TextStyle(
                color: _isOpen ? Colors.green : Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeStr,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
            ),
            child: Icon(
              Icons.auto_awesome_mosaic_outlined,
              color: cs.onSurface.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildOpen(BuildContext context, ColorScheme cs) {
    return ValueListenableBuilder<bool>(
      valueListenable: checkedInNotifier,
      builder: (_, checkedIn, _) => checkedIn
          ? _buildGuildInside(context, cs)
          : _buildCheckIn(context, cs),
    );
  }

  Widget _buildCheckIn(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(Icons.temple_hindu, color: cs.secondary, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Sect Hall',
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '08:00 — 23:00',
            style: GoogleFonts.jetBrainsMono(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  'To enter you must perform\nmorning meditation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isCheckingIn ? null : _handleCheckIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 28,
                    ),
                    decoration: BoxDecoration(
                      color: _isCheckingIn
                          ? cs.primary.withValues(alpha: 0.5)
                          : cs.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isCheckingIn
                          ? null
                          : [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                    ),
                    child: _isCheckingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.self_improvement, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'MEDITATE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: checkedInNotifier,
            builder: (_, checkedIn, _) {
              final player = playerNotifier.value;
              final String label;
              if (checkedIn) {
                label = 'Morning ritual: Complete';
              } else if (player.daoHeartStreak > 0) {
                label = 'Dao Heart: ${player.daoHeartStreak} days';
              } else {
                label = 'Last ritual: Ancient history';
              }
              return Text(
                label,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.25),
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuildInside(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: cs.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE SYSTEM',
                        style: GoogleFonts.cinzel(
                          color: cs.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"Synchronization established. Transmit your progress."',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GuildMasterScreen(),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Transmit Intent →',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Sect Library button — Shadow Arts only
          if (playerNotifier.value.sect == 'Shadow Arts')
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LibraryScreen(),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, color: cs.onSurface.withValues(alpha: 0.7), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Sect Library',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: cs.onSurface.withValues(alpha: 0.3), size: 12),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'TRIAL BOARD',
            style: GoogleFonts.cinzel(
              color: cs.onSurface.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<Quest>>(
            valueListenable: guildBoardNotifier,
            builder: (_, guildQuests, _) {
              if (guildQuests.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_edu,
                        size: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No trials inscribed',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Speak with the System to manifest new trials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.2),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ValueListenableBuilder<List<Quest>>(
                valueListenable: questNotifier,
                builder: (_, accepted, _) {
                  return Column(
                    children: guildQuests
                        .map((q) => _buildGuildBoardCard(q, accepted, cs))
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuildBoardCard(
    Quest quest,
    List<Quest> acceptedQuests,
    ColorScheme cs,
  ) {
    final isAccepted = acceptedQuests.any((q) => q.id == quest.id);
    final rankColor = _guildRankColor(quest.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAccepted
              ? Colors.green.withValues(alpha: 0.35)
              : rankColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: rankColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              quest.rank,
              style: GoogleFonts.jetBrainsMono(
                color: rankColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${quest.xpReward} Qi · ${quest.classTag}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isAccepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'ACCEPTED',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _guildRankColor(String rank) => rc.rankColor(rank);

  Widget _buildGuildClosed(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_person_outlined,
              size: 52,
              color: cs.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Text(
              'The Sect Hall is sealed.',
              style: GoogleFonts.cinzel(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accessible at 08:00.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '"Rest. The trials will manifest when the sun rises."',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.25),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
