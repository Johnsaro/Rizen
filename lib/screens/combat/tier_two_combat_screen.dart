import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_state.dart';
import '../../models/combat_question.dart';
import '../../models/combat_question_bank.dart';
import '../../models/combat_session.dart';
import '../../models/player_data.dart';
import '../../services/combat_service.dart';
import '../../services/flashcard_service.dart';
import 'countdown_timer.dart';
import 'question_card.dart';
import '../../widgets/glass_card.dart';

class TierTwoCombatScreen extends StatefulWidget {
  final String bossName;
  final int bossMaxHp;
  final IconData bossIcon;

  const TierTwoCombatScreen({
    super.key,
    this.bossName = 'Laziness Archon',
    this.bossMaxHp = 1200,
    this.bossIcon = Icons.local_fire_department,
  });

  @override
  State<TierTwoCombatScreen> createState() => _TierTwoCombatScreenState();
}

class _TierTwoCombatScreenState extends State<TierTwoCombatScreen>
    with SingleTickerProviderStateMixin {
  CombatService? _service;
  bool _hasWeaponHint = false;
  final _savingNotifier = ValueNotifier<bool>(false);

  // Hit animation state
  bool _playerHit = false;
  bool _bossHit = false;

  // Slide-up panel
  bool _panelVisible = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final player = playerNotifier.value;
    List<CombatQuestion> questions;

    bool weaponHint = false;
    if (player.equippedWeapon.isNotEmpty) {
      try {
        final fetched =
            await FlashcardService.fetchByWeapon(player.equippedWeapon);
        if (fetched.isNotEmpty) {
          questions = fetched;
          weaponHint = true;
        } else {
          questions = _classFilteredFallback(player);
        }
      } catch (_) {
        questions = _classFilteredFallback(player);
      }
    } else {
      questions = _classFilteredFallback(player);
    }

    if (!mounted) return;
    setState(() {
      _hasWeaponHint = weaponHint;
      _service = CombatService(
        questions: questions,
        monsterName: widget.bossName,
        monsterId: widget.bossName.toLowerCase().replaceAll(' ', '_'),
        monsterMaxHp: widget.bossMaxHp,
        playerHp: player.hp,
        playerMaxHp: player.maxHp,
        playerXP: player.qi,
        playerLevel: player.level,
      );
    });
    // Slide panel in after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _panelVisible = true);
    });
  }

  @override
  void dispose() {
    _savingNotifier.dispose();
    _service?.dispose();
    super.dispose();
  }

  List<CombatQuestion> _classFilteredFallback(PlayerData player) {
    final filtered = CombatQuestionBank.all
        .where((q) =>
            q.classTag == player.mainPath ||
            q.classTag == 'Any')
        .toList();
    return filtered.isNotEmpty ? filtered : CombatQuestionBank.all;
  }

  Future<void> _onFlee() async {
    if (_service == null || _service!.isFightOver || !_service!.canFlee) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Retreat from the Boss?', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Text(
          'You will abandon this ascension trial and lose ${CombatService.fleePenaltyXp} Qi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RETREAT'),
          ),
        ],
      ),
    );
    if (confirmed == true) _service?.flee();
  }

  Future<void> _onContinue() async {
    if (_savingNotifier.value) return;
    _savingNotifier.value = true;
    try {
      if (_service!.result == CombatResult.victory) {
        await gameService.applyCombatVictory(
          _service!.xpReward,
          _service!.combatClassTag,
        );
      } else if (_service!.result == CombatResult.defeat) {
        await gameService.applyCombatDeath(_service!.defeatXpLoss);
      } else if (_service!.result == CombatResult.fled) {
        await gameService.applyCombatFlee(CombatService.fleePenaltyXp);
      }
    } finally {
      _savingNotifier.value = false;
      if (mounted) Navigator.pop(context);
    }
  }

  void _onAnswer(int index) {
    if (_service == null) return;
    final wasCorrect =
        index >= 0 && index == _service!.currentQuestion.correctIndex;

    _service!.answerQuestion(index);

    // Trigger hit animation
    setState(() {
      if (wasCorrect) {
        _bossHit = true;
      } else {
        _playerHit = true;
      }
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() { _bossHit = false; _playerHit = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onFlee();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _service!,
            builder: (ctx, _) {
              final cs = Theme.of(ctx).colorScheme;
              return Stack(
                children: [
                  // Main arena layout
                  Column(
                    children: [
                      _buildTopBar(ctx, cs),
                      Expanded(child: _buildArena(cs)),
                    ],
                  ),
                  // Slide-up question panel
                  _buildSlideUpPanel(cs),
                  // Result overlay
                  if (_service!.isFightOver) _buildResultOverlay(ctx, cs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // -- Top bar -----------------------------------------------------------

  Widget _buildTopBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _service!.canFlee ? _onFlee : null,
            child: Icon(
              Icons.arrow_back_ios,
              color: cs.onSurface
                  .withValues(alpha: _service!.canFlee ? 0.4 : 0.15),
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            'TRIAL OF ASCENSION',
            style: GoogleFonts.cinzel(
              color: cs.error.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _service!.canFlee ? _onFlee : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _service!.canFlee
                      ? cs.outline
                      : cs.error.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _service!.canFlee ? 'RETREAT' : 'LOCKED',
                style: TextStyle(
                  color: _service!.canFlee
                      ? cs.onSurface.withValues(alpha: 0.4)
                      : cs.error.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Arena with sprites ------------------------------------------------

  Widget _buildArena(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Boss Vitality bar
          _buildHpRow(
            label: widget.bossName.toUpperCase(),
            current: _service!.monsterCurrentHp,
            max: _service!.monsterMaxHp,
            fraction: _service!.monsterHpFraction,
            barColor: _bossHpColor,
            cs: cs,
          ),
          const Spacer(),
          // Sprites row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerSprite(cs),
              // Damage indicators in center
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_service!.lastDamageToMonster != null)
                      Text(
                        '-${_service!.lastDamageToMonster}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_service!.lastDamageToPlayer != null)
                      Text(
                        '-${_service!.lastDamageToPlayer} VITALITY',
                        style: TextStyle(
                          color: (_service!.wasLastAnswerCorrect ?? true)
                              ? Colors.orange
                              : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              _buildBossSprite(cs),
            ],
          ),
          const Spacer(),
          // Player Vitality bar
          _buildHpRow(
            label: 'VITALITY',
            current: _service!.playerCurrentHp,
            max: _service!.playerMaxHp,
            fraction: _service!.playerHpFraction,
            barColor: _playerHpColor,
            cs: cs,
          ),
          const SizedBox(height: 8),
          // Timer
          SizedBox(
            height: 40,
            child: _service!.isPlayerTurn && !_service!.isFightOver
                ? Center(
                    child: CountdownTimer(
                      key: ValueKey(_service!.currentRound),
                      seconds: 15,
                      onTimeout: () => _onAnswer(-1),
                    ),
                  )
                : null,
          ),
          // Spacer for question panel
          const SizedBox(height: 220),
        ],
      ),
    );
  }

  Color get _bossHpColor {
    final f = _service!.monsterHpFraction;
    return f > 0.5
        ? Colors.red.shade400
        : f > 0.25
            ? Colors.orange.shade400
            : Colors.red.shade900;
  }

  Color get _playerHpColor {
    final f = _service!.playerHpFraction;
    return f > 0.5
        ? Colors.green.shade400
        : f > 0.25
            ? Colors.yellow.shade700
            : Colors.red.shade400;
  }

  Widget _buildHpRow({
    required String label,
    required int current,
    required int max,
    required double fraction,
    required Color barColor,
    required ColorScheme cs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$current / $max',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 8, color: cs.outline),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: fraction),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (_, value, _) => FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(height: 8, color: barColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -- Sprites -----------------------------------------------------------

  Widget _buildPlayerSprite(ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(_playerHit ? 8 : 0, 0, 0),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _playerHit
              ? Colors.red.withValues(alpha: 0.15)
              : cs.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: _playerHit
                ? Colors.red.withValues(alpha: 0.5)
                : cs.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 48,
              color: _playerHit
                  ? Colors.red.withValues(alpha: 0.6)
                  : cs.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'YOU',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBossSprite(ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(_bossHit ? -8 : 0, 0, 0),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _bossHit
              ? Colors.green.withValues(alpha: 0.15)
              : cs.error.withValues(alpha: 0.08),
          border: Border.all(
            color: _bossHit
                ? Colors.green.withValues(alpha: 0.5)
                : cs.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.bossIcon,
              size: 48,
              color: _bossHit
                  ? Colors.green.withValues(alpha: 0.6)
                  : cs.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              'GREAT BEAST',
              style: TextStyle(
                color: cs.error.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Slide-up question panel -------------------------------------------

  Widget _buildSlideUpPanel(ColorScheme cs) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: _panelVisible && !_service!.isFightOver ? 0 : -300,
      child: QuestionCard(
        questionText: _service!.currentQuestion.questionText,
        options: _service!.currentQuestion.options,
        correctIndex: _service!.currentQuestion.correctIndex,
        selectedIndex: _service!.selectedAnswerIndex,
        isEnabled: _service!.isPlayerTurn && !_service!.isFightOver,
        onAnswer: _onAnswer,
        showWeaponHint: _hasWeaponHint,
      ),
    );
  }

  // -- Result overlay ----------------------------------------------------

  Widget _buildResultOverlay(BuildContext context, ColorScheme cs) {
    final isVictory = _service!.result == CombatResult.victory;
    final isFled = _service!.result == CombatResult.fled;

    final title = isVictory
        ? 'BEAST VANQUISHED'
        : isFled
            ? 'RETREATED'
            : 'DEFEATED';

    final subtitle = isVictory
        ? '${widget.bossName} has been subdued.'
        : isFled
            ? 'You escaped the ascension arena.'
            : 'The beast proved too powerful for your current base.';

    final color = isVictory
        ? Colors.green
        : isFled
            ? cs.primary
            : Colors.red;

    final icon = isVictory
        ? Icons.stars
        : isFled
            ? Icons.directions_run
            : Icons.dangerous;

    String? xpDeltaText;
    Color? xpDeltaColor;
    if (isVictory) {
      if (_service!.xpReward > 0) {
        xpDeltaText = '+${_service!.xpReward} Qi';
        xpDeltaColor = Colors.green;
      }
    } else if (isFled) {
      xpDeltaText = '-${CombatService.fleePenaltyXp} Qi';
      xpDeltaColor = Colors.red;
    } else {
      final loss = _service!.defeatXpLoss;
      if (loss > 0) {
        xpDeltaText = '-$loss Qi';
        xpDeltaColor = Colors.red;
      }
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            borderRadius: 16.0,
            backgroundColor: cs.surface.withValues(alpha: 0.3),
            borderColor: color.withValues(alpha: 0.5),
            blurRadius: 15.0,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 52),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.cinzel(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              if (xpDeltaText != null) ...[
                const SizedBox(height: 12),
                Text(
                  xpDeltaText,
                  style: GoogleFonts.jetBrainsMono(
                    color: xpDeltaColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ValueListenableBuilder<bool>(
                valueListenable: _savingNotifier,
                builder: (_, isSaving, _) => GestureDetector(
                  onTap: isSaving ? null : _onContinue,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          isSaving ? color.withValues(alpha: 0.5) : color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isSaving
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                          )
                        : const Text(
                            'CONTINUE',
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
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
