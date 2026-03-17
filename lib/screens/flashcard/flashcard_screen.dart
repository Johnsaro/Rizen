import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/combat_question.dart';
import '../../services/flashcard_service.dart';
import '../combat/countdown_timer.dart';

enum FlashcardMode { study, repair }

class FlashcardScreen extends StatefulWidget {
  final String weaponTag;
  final FlashcardMode mode;
  final int requiredCorrect;

  const FlashcardScreen({
    super.key,
    required this.weaponTag,
    required this.mode,
    this.requiredCorrect = 3,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<CombatQuestion> _deck = [];
  List<CombatQuestion> _originalDeck = [];
  bool _loading = true;
  String? _error;

  // Shared
  int _currentIndex = 0;
  bool _done = false;

  // Meditation mode
  bool _isRevealed = false;
  int _gotCount = 0;
  int _missedCount = 0;

  // Refinement mode
  int _correctCount = 0;
  int _attempts = 0;
  int _timerKey = 0;
  bool _showingFeedback = false;
  bool? _lastResult; // null = pending, true = correct, false = wrong
  bool _repairPassed = false;

  int get _failLimit => widget.requiredCorrect * 3;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      var questions = await FlashcardService.fetchByWeapon(widget.weaponTag);
      questions.shuffle();
      if (mounted) {
        setState(() {
          _originalDeck = List<CombatQuestion>.from(questions);
          _deck = List<CombatQuestion>.from(questions);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to manifest Jade Slips. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  // ── Study handlers ────────────────────────────────────────────────────

  void _onReveal() => setState(() => _isRevealed = true);

  void _onStudyRate(bool got) {
    if (got) {
      _gotCount++;
    } else {
      _missedCount++;
    }
    if (_currentIndex >= _deck.length - 1) {
      setState(() => _done = true);
    } else {
      setState(() {
        _currentIndex++;
        _isRevealed = false;
      });
    }
  }

  // ── Refinement handlers ───────────────────────────────────────────────────

  void _onRepairAnswer(int selectedIndex) {
    if (_showingFeedback) return;
    _handleRepairResult(selectedIndex == _deck[_currentIndex].correctIndex);
  }

  void _onRepairTimeout() {
    if (_showingFeedback) return;
    _handleRepairResult(false);
  }

  void _handleRepairResult(bool correct) {
    if (!mounted) return;
    _attempts++;
    if (correct) {
      _correctCount++;
    } else {
      _deck.add(_deck[_currentIndex]); // recycle failed card to end of deck
    }
    setState(() {
      _lastResult = correct;
      _showingFeedback = true;
    });

    final passed = _correctCount >= widget.requiredCorrect;
    final failed = !passed && _attempts >= _failLimit;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (passed || failed) {
        setState(() {
          _repairPassed = passed;
          _done = true;
        });
      } else {
        setState(() {
          _currentIndex++;
          _timerKey++;
          _lastResult = null;
          _showingFeedback = false;
        });
      }
    });
  }

  void _retryRepair() {
    setState(() {
      _deck = List<CombatQuestion>.from(_originalDeck)..shuffle();
      _currentIndex = 0;
      _correctCount = 0;
      _attempts = 0;
      _timerKey++;
      _showingFeedback = false;
      _lastResult = null;
      _done = false;
      _repairPassed = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.mode == FlashcardMode.study ? 'Jade Slip Study' : 'Refinement Mode';

    if (_loading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return _buildErrorState(cs);
    if (_deck.isEmpty) return _buildEmptyState(cs);
    if (_done) {
      return widget.mode == FlashcardMode.study
          ? _buildStudySummary(cs)
          : _buildRepairResult(cs);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs, title),
            Expanded(
              child: widget.mode == FlashcardMode.study
                  ? _buildStudyCard(cs)
                  : _buildRepairCard(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, String title) {
    final progress = widget.mode == FlashcardMode.study
        ? '${_currentIndex + 1} / ${_deck.length}'
        : '$_correctCount / ${widget.requiredCorrect}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
            color: cs.onSurface,
          ),
          Text(
            title,
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          if (!_done)
            Text(
              progress,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ── Study UI ──────────────────────────────────────────────────────────

  Widget _buildStudyCard(ColorScheme cs) {
    final q = _deck[_currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                q.weaponTag,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              q.questionText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (!_isRevealed) ...[
            FilledButton(
              onPressed: _onReveal,
              child: const Text('Comprehend Script'),
            ),
          ] else ...[
            Text(
              'TRUE COMPREHENSION',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(q.options.length, (i) => _buildStudyOption(i, q, cs)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onStudyRate(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Obscure'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _onStudyRate(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Gained Insight'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudyOption(int index, CombatQuestion q, ColorScheme cs) {
    final isCorrect = index == q.correctIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect
              ? Colors.green
              : cs.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCorrect
                    ? Colors.green
                    : cs.outline.withValues(alpha: 0.35),
              ),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  color: isCorrect
                      ? Colors.green
                      : cs.onSurface.withValues(alpha: 0.25),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              q.options[index],
              style: TextStyle(
                color: isCorrect
                    ? Colors.green
                    : cs.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ],
      ),
    );
  }

  // ── Refinement UI ─────────────────────────────────────────────────────────

  Widget _buildRepairCard(ColorScheme cs) {
    final q = _deck[_currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRepairProgress(cs),
          const SizedBox(height: 16),
          CountdownTimer(
            key: ValueKey(_timerKey),
            seconds: 10,
            onTimeout: _onRepairTimeout,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              q.questionText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(q.options.length, (i) => _buildRepairOption(i, q, cs)),
          if (_showingFeedback && _lastResult != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _lastResult! ? '✓ Insight Gained!' : '✗ Failed to comprehend script',
                style: TextStyle(
                  color: _lastResult! ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepairOption(int index, CombatQuestion q, ColorScheme cs) {
    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (_lastResult != null) {
      if (index == q.correctIndex) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
        textColor = Colors.green;
      } else {
        borderColor = cs.outline.withValues(alpha: 0.2);
        bgColor = Colors.transparent;
        textColor = cs.onSurface.withValues(alpha: 0.2);
      }
    } else {
      borderColor = cs.outline;
      bgColor = Colors.transparent;
      textColor = cs.onSurface.withValues(alpha: 0.85);
    }

    return GestureDetector(
      onTap: !_showingFeedback ? () => _onRepairAnswer(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                q.options[index],
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairProgress(ColorScheme cs) {
    final fraction = (_correctCount / widget.requiredCorrect).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Refinement Progress',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$_correctCount / ${widget.requiredCorrect} insights',
              style: TextStyle(
                fontSize: 12,
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: cs.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
      ],
    );
  }

  // ── End states ────────────────────────────────────────────────────────

  Widget _buildStudySummary(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories, size: 64, color: cs.primary),
              const SizedBox(height: 20),
              Text(
                'Meditation Complete',
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.weaponTag,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip('$_gotCount', 'Insights', Colors.green, cs),
                  const SizedBox(width: 16),
                  _buildStatChip('$_missedCount', 'Obscure', Colors.red, cs),
                  const SizedBox(width: 16),
                  _buildStatChip(
                    '${_originalDeck.length}',
                    'Total',
                    cs.primary,
                    cs,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Conclude Meditation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepairResult(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _repairPassed
                    ? Icons.auto_fix_high
                    : Icons.cancel_outlined,
                size: 72,
                color: _repairPassed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                _repairPassed ? 'Artifact Refined!' : 'Refinement Failed',
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _repairPassed ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.weaponTag,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$_correctCount / ${widget.requiredCorrect} insights gained',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),
              if (!_repairPassed) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _retryRepair,
                    child: const Text('Attempt Again'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Exit State'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              cs,
              widget.mode == FlashcardMode.study ? 'Study' : 'Repair',
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 56,
                        color: cs.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No scripts discovered',
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Jade Slips found for "${widget.weaponTag}".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              cs,
              widget.mode == FlashcardMode.study ? 'Study' : 'Repair',
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_outlined,
                        size: 56,
                        color: cs.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connection severed',
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadQuestions();
                        },
                        child: const Text('Retry Connection'),
                      ),
                    ],
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
