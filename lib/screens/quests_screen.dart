import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/quest.dart';
import '../theme/rank_colors.dart' as rc;
import '../widgets/floating_xp.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  int _selectedTab = 0;
  final Set<String> _completingIds = {};

  static const _tabs = ['Daily', 'Main', 'Side'];

  static Color _rankColor(String rank) => rc.rankColor(rank);

  String _tabType(int index) {
    switch (index) {
      case 0: return 'daily';
      case 1: return 'main';
      case 2: return 'side';
      default: return 'daily';
    }
  }

  Future<void> _completeQuest(Quest quest) async {
    if (quest.isCompleted || _completingIds.contains(quest.id)) return;
    setState(() => _completingIds.add(quest.id));
    final saved = await gameService.completeQuest(quest);
    if (!mounted) return;
    if (saved) {
      // Persisted: show reward animation.
      final repGain = (quest.xpReward * 0.1).round();
      showFloatingText(context, '+${quest.xpReward} QI  +$repGain STONES');
    } else {
      // Failed: restore button so the user can retry.
      setState(() => _completingIds.remove(quest.id));
    }
  }


  /// Returns a deadline label + urgency color for a quest.
  /// Returns null if the quest has no deadline or is already completed.
  ({String label, Color color})? _deadlineInfo(Quest quest) {
    if (quest.isCompleted || quest.deadline.isEmpty) return null;
    try {
      final deadline = DateTime.parse(quest.deadline);
      final now = DateTime.now();
      final diff = deadline.difference(DateTime(now.year, now.month, now.day));
      final days = diff.inDays;

      if (days < 0) {
        return (label: 'Expired', color: const Color(0xFFEF5350));
      } else if (days == 0) {
        return (label: 'Today', color: const Color(0xFFFB923C));
      } else if (days == 1) {
        return (label: '1d left', color: const Color(0xFFFFA726));
      } else if (days <= 3) {
        return (label: '${days}d left', color: const Color(0xFFFFA726));
      } else {
        return (label: '${days}d left', color: const Color(0xFF9E9E9E));
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(cs),
            const SizedBox(height: 8),
            _buildTabs(cs),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<List<Quest>>(
                valueListenable: questNotifier,
                builder: (_, quests, _) => _buildQuestList(cs, quests),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TRIAL BOARD',
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Icon(Icons.timer_outlined,
              color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)), size: 20),
        ],
      ),
    );
  }

  Widget _buildTabs(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outline,
                    width: 1,
                  ),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: selected
                        ? cs.onPrimary
                        : (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuestList(ColorScheme cs, List<Quest> allQuests) {
    final type = _tabType(_selectedTab);
    final quests = allQuests.where((q) => q.type == type).toList();

    if (quests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined,
                  size: 48, color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.1) : const Color(0xFF4B5563))),
              const SizedBox(height: 16),
              Text(
                'No ${_tabs[_selectedTab].toLowerCase()} trials available.\nTalk to the Dao Guide.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.4) : const Color(0xFF4B5563)),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: quests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildQuestCard(
          cs, quests[i], _completingIds.contains(quests[i].id)),
    );
  }

  Widget _buildQuestCard(ColorScheme cs, Quest quest, bool isCompleting) {
    final rankColor = _rankColor(quest.rank);
    final completed = quest.isCompleted;
    final deadlineInfo = _deadlineInfo(quest);

    return Opacity(
      opacity: completed ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: completed ? cs.outline : rankColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        // Clip so the left accent bar respects the border radius
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left rank color accent bar
                Container(
                  width: 4,
                  color: completed
                      ? cs.outline
                      : rankColor.withValues(alpha: 0.7),
                ),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: rank badge + title + Qi label
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rank badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: rankColor.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                quest.rank,
                                style: GoogleFonts.jetBrainsMono(
                                  color: rankColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Title
                            Expanded(
                              child: Text(
                                quest.title,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Qi reward
                            Text(
                              '+${quest.xpReward} QI',
                              style: GoogleFonts.jetBrainsMono(
                                color: cs.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        // Description
                        Text(
                          quest.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.55) : const Color(0xFF4B5563)),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Bottom row: classTag + deadline + complete/done button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Class tag chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        (cs.brightness == Brightness.dark ? cs.onSurface.withValues(alpha: 0.06) : const Color(0xFF4B5563)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    quest.classTag,
                                    style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                // Deadline badge
                                if (deadlineInfo != null) ...[
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.hourglass_empty,
                                          size: 11,
                                          color: deadlineInfo.color),
                                      const SizedBox(width: 3),
                                      Text(
                                        deadlineInfo.label,
                                        style: GoogleFonts.jetBrainsMono(
                                          color: deadlineInfo.color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            // COMPLETE / DONE button
                            completed
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.35),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'FINISHED',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.35),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  )
                                : GestureDetector(
                                    onTap: isCompleting
                                        ? null
                                        : () => _completeQuest(quest),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: rankColor.withValues(
                                            alpha: isCompleting ? 0.08 : 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: rankColor.withValues(
                                              alpha:
                                                  isCompleting ? 0.25 : 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: isCompleting
                                          ? SizedBox(
                                              width: 11,
                                              height: 11,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: rankColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                            )
                                          : Text(
                                              'REALIZE',
                                              style: GoogleFonts.jetBrainsMono(
                                                color: rankColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                          ],
                        ),
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
}
