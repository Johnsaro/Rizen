import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_state.dart';
import '../../models/sect_path.dart';
import '../../models/player_path.dart';
import '../../services/supabase_service.dart';
import '../../theme/night_guild_background.dart';
import 'lesson_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  SectPath? _sectPath;
  PlayerPath? _playerPath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final player = playerNotifier.value;

      // Load sect path definition for the player's active path
      final paths = await SupabaseService.loadSectPaths(player.sect);
      final sectPath = paths.firstWhere(
        (p) => p.pathName == player.activePath,
      );

      // Load player's path progress
      final playerPaths = await SupabaseService.loadPlayerPaths(userId);
      final playerPath = playerPaths.firstWhere(
        (pp) => pp.pathId == sectPath.id,
      );

      if (mounted) {
        setState(() {
          _sectPath = sectPath;
          _playerPath = playerPath;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load library: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openLesson(String topic) async {
    if (_sectPath == null || _playerPath == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          sectPath: _sectPath!,
          playerPath: _playerPath!,
          topic: topic,
        ),
      ),
    );

    // Refresh if the lesson was completed (topic marked as studied)
    if (result == true) {
      await _loadData();
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
              _buildTopBar(cs),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(child: _buildError(cs))
              else
                Expanded(child: _buildTopicList(cs)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SECT LIBRARY',
              style: GoogleFonts.cinzel(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          if (_playerPath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Rank ${_playerPath!.rank}',
                style: GoogleFonts.spaceMono(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: cs.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicList(ColorScheme cs) {
    final sectPath = _sectPath!;
    final playerPath = _playerPath!;
    final currentRank = playerPath.rank;

    // Build grouped topic list: current rank first, then lower ranks
    final rankIdx = SectPath.rankOrder.indexOf(currentRank);
    final sections = <_TopicSection>[];

    for (var i = rankIdx; i >= 0; i--) {
      final rank = SectPath.rankOrder[i];
      final topics = sectPath.topicsAtRank(rank);
      if (topics.isNotEmpty) {
        sections.add(_TopicSection(
          rank: rank,
          isCurrent: rank == currentRank,
          topics: topics,
        ));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: sections.length,
      itemBuilder: (_, sectionIdx) {
        final section = sections[sectionIdx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionIdx > 0) const SizedBox(height: 20),
            _buildSectionHeader(cs, section),
            const SizedBox(height: 8),
            ...section.topics.map(
              (topic) => _buildTopicTile(cs, topic, playerPath),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, _TopicSection section) {
    return Row(
      children: [
        Text(
          'RANK ${section.rank}',
          style: GoogleFonts.spaceMono(
            color: section.isCurrent
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        if (section.isCurrent) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'CURRENT',
              style: GoogleFonts.spaceMono(
                color: cs.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopicTile(
      ColorScheme cs, String topic, PlayerPath playerPath) {
    final studied = playerPath.hasStudied(topic);
    final accuracy = playerPath.accuracyFor(topic);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLesson(topic),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: studied
                  ? cs.primary.withValues(alpha: 0.08)
                  : cs.surface.withValues(alpha: 0.6),
              border: Border.all(
                color: studied
                    ? cs.primary.withValues(alpha: 0.3)
                    : cs.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Status icon
                Icon(
                  studied ? Icons.check_circle : Icons.circle_outlined,
                  color: studied
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(width: 12),
                // Topic name
                Expanded(
                  child: Text(
                    topic,
                    style: GoogleFonts.spaceMono(
                      color: cs.onSurface,
                      fontSize: 13,
                      fontWeight:
                          studied ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Accuracy badge (if studied and has data)
                if (studied && accuracy != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accuracyColor(accuracy).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(accuracy * 100).round()}%',
                      style: GoogleFonts.spaceMono(
                        color: _accuracyColor(accuracy),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: cs.onSurface.withValues(alpha: 0.3),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.5) return Colors.amber;
    return Colors.red;
  }
}

class _TopicSection {
  final String rank;
  final bool isCurrent;
  final List<String> topics;
  const _TopicSection({
    required this.rank,
    required this.isCurrent,
    required this.topics,
  });
}
