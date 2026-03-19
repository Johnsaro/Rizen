import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lesson.dart';
import '../../models/sect_path.dart';
import '../../models/player_path.dart';
import '../../services/ai_lesson_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/night_guild_background.dart';

class LessonScreen extends StatefulWidget {
  final SectPath sectPath;
  final PlayerPath playerPath;
  final String topic;

  const LessonScreen({
    super.key,
    required this.sectPath,
    required this.playerPath,
    required this.topic,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

enum _LessonPhase { loading, reading, quiz, results }

class _LessonScreenState extends State<LessonScreen> {
  _LessonPhase _phase = _LessonPhase.loading;
  Lesson? _lesson;
  String? _error;

  // Quiz state
  int _currentQuestion = 0;
  final List<int?> _answers = []; // selected index per question
  int _correctCount = 0;

  bool get _alreadyStudied => widget.playerPath.hasStudied(widget.topic);

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _phase = _LessonPhase.loading;
      _error = null;
    });

    try {
      final lesson = await AiLessonService.getLesson(
        pathId: widget.sectPath.id,
        pathName: widget.sectPath.pathName,
        domain: widget.sectPath.domain,
        topic: widget.topic,
        rank: widget.playerPath.rank,
      );

      if (mounted) {
        setState(() {
          _lesson = lesson;
          _answers.addAll(
              List<int?>.filled(lesson.quizQuestions.length, null));
          _phase = _LessonPhase.reading;
        });
      }
    } on LessonGenerationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    }
  }

  void _startQuiz() {
    setState(() => _phase = _LessonPhase.quiz);
  }

  void _selectAnswer(int questionIdx, int choiceIdx) {
    if (_answers[questionIdx] != null) return; // already answered
    setState(() {
      _answers[questionIdx] = choiceIdx;
      if (choiceIdx == _lesson!.quizQuestions[questionIdx].correctIndex) {
        _correctCount++;
      }
    });

    // Auto-advance after a short delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQuestion < _lesson!.quizQuestions.length - 1) {
        setState(() => _currentQuestion++);
      } else {
        _finishQuiz();
      }
    });
  }

  Future<void> _finishQuiz() async {
    setState(() => _phase = _LessonPhase.results);

    final passed = _correctCount >= 2; // 2/3 to pass
    if (passed && !_alreadyStudied) {
      await _markTopicStudied();
    }
  }

  Future<void> _markTopicStudied() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Reload fresh player path to avoid stale data
      final playerPaths = await SupabaseService.loadPlayerPaths(userId);
      final fresh = playerPaths.firstWhere(
        (pp) => pp.pathId == widget.sectPath.id,
      );

      // Add topic to studied list
      final updatedTopics = [...fresh.studiedTopics, widget.topic];

      // Update accuracy stats
      final total = _lesson!.quizQuestions.length;
      final updatedStats = Map<String, Map<String, int>>.from(
        fresh.accuracyStats,
      );
      updatedStats[widget.topic] = {
        'correct': _correctCount,
        'total': total,
      };

      final updated = fresh.copyWith(
        studiedTopics: updatedTopics,
        accuracyStats: updatedStats,
        updatedAt: DateTime.now().toUtc(),
      );

      await SupabaseService.savePlayerPath(updated);
    } catch (e) {
      debugPrint('Failed to mark topic studied: $e');
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
              Expanded(child: _buildBody(cs)),
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
            onTap: () => Navigator.of(context).pop(
              _phase == _LessonPhase.results && _correctCount >= 2,
            ),
            child: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.topic.toUpperCase(),
              style: GoogleFonts.cinzel(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    return switch (_phase) {
      _LessonPhase.loading => _error != null
          ? _buildError(cs)
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating lesson...'),
                ],
              ),
            ),
      _LessonPhase.reading => _buildLessonReader(cs),
      _LessonPhase.quiz => _buildQuiz(cs),
      _LessonPhase.results => _buildResults(cs),
    };
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
              style: TextStyle(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLesson,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonReader(ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildMarkdownContent(cs, _lesson!.lessonContent),
          ),
        ),
        // "Take Quiz" button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _alreadyStudied ? 'RETAKE QUIZ' : 'BEGIN COMPREHENSION TEST',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Simple markdown-ish renderer for lesson content.
  Widget _buildMarkdownContent(ColorScheme cs, String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(4),
            style: GoogleFonts.cinzel(
              color: cs.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            line.substring(3),
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(2),
            style: GoogleFonts.cinzel(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('```')) {
        // Skip code fence markers — content between them gets code styling
        continue;
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('  \u2022  ',
                  style: TextStyle(color: cs.primary, fontSize: 14)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: TextStyle(
                      color: cs.onSurface, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        // Apply inline bold (**text**)
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildInlineFormatted(cs, line),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInlineFormatted(ColorScheme cs, String text) {
    // Simple bold parser for **text**
    final parts = text.split(RegExp(r'\*\*'));
    if (parts.length <= 1) {
      return Text(
        text,
        style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.5),
      );
    }

    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 14,
          height: 1.5,
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildQuiz(ColorScheme cs) {
    final questions = _lesson!.quizQuestions;
    if (questions.isEmpty) {
      // Edge case: no quiz questions generated
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishQuiz());
      return const Center(child: CircularProgressIndicator());
    }

    final q = questions[_currentQuestion];
    final selectedIdx = _answers[_currentQuestion];
    final answered = selectedIdx != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                'Question ${_currentQuestion + 1} of ${questions.length}',
                style: GoogleFonts.spaceMono(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$_correctCount correct',
                style: GoogleFonts.spaceMono(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / questions.length,
            backgroundColor: cs.outline.withValues(alpha: 0.2),
            color: cs.primary,
          ),
          const SizedBox(height: 24),

          // Question
          Text(
            q.question,
            style: GoogleFonts.spaceMono(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Choices
          ...List.generate(q.choices.length, (i) {
            final isSelected = selectedIdx == i;
            final isCorrect = i == q.correctIndex;
            Color tileColor = cs.surface.withValues(alpha: 0.6);
            Color borderColor = cs.outline.withValues(alpha: 0.2);

            if (answered) {
              if (isCorrect) {
                tileColor = Colors.green.withValues(alpha: 0.15);
                borderColor = Colors.green.withValues(alpha: 0.5);
              } else if (isSelected) {
                tileColor = Colors.red.withValues(alpha: 0.15);
                borderColor = Colors.red.withValues(alpha: 0.5);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: answered
                      ? null
                      : () => _selectAnswer(_currentQuestion, i),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: tileColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${['A', 'B', 'C', 'D'][i]}.',
                          style: GoogleFonts.spaceMono(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.choices[i],
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (answered && isCorrect)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                        if (answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel,
                              color: Colors.red, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Explanation (shown after answering)
          if (answered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: cs.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      q.explanation,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(ColorScheme cs) {
    final total = _lesson!.quizQuestions.length;
    final passed = _correctCount >= 2;
    final wasAlreadyStudied = _alreadyStudied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.replay,
              color: passed ? Colors.amber : cs.error,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              passed ? 'COMPREHENSION PASSED' : 'NOT YET',
              style: GoogleFonts.cinzel(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_correctCount / $total correct',
              style: GoogleFonts.spaceMono(
                color: cs.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              passed
                  ? wasAlreadyStudied
                      ? 'Knowledge refreshed.'
                      : 'Topic mastered. This knowledge is now yours.'
                  : 'You need at least 2 correct. Re-read the lesson and try again.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!passed)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _phase = _LessonPhase.reading;
                      _currentQuestion = 0;
                      _answers.fillRange(0, _answers.length, null);
                      _correctCount = 0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'RE-READ LESSON',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  passed && !wasAlreadyStudied,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      passed ? cs.primary : cs.surface,
                  foregroundColor:
                      passed ? cs.onPrimary : cs.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'RETURN TO LIBRARY',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
