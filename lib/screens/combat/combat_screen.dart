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
import 'monster_hp_bar.dart';
import 'player_hp_bar.dart';
import 'question_card.dart';

class CombatScreen extends StatefulWidget {
  final String monsterName;
  final int monsterMaxHp;

  const CombatScreen({
    super.key,
    this.monsterName = 'Procrastination Specter',
    this.monsterMaxHp = 800,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  CombatService? _service;
  bool _hasWeaponHint = false;
  final _savingNotifier = ValueNotifier<bool>(false);

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
        final fetched = await FlashcardService.fetchByWeapon(player.equippedWeapon);
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
        monsterName: widget.monsterName,
        monsterId: widget.monsterName.toLowerCase().replaceAll(' ', '_'),
        monsterMaxHp: widget.monsterMaxHp,
        playerHp: player.hp,
        playerMaxHp: player.maxHp,
        playerXP: player.qi,
        playerLevel: player.level,
      );
    });
  }

  @override
  void dispose() {
    _savingNotifier.dispose();
    _service?.dispose();
    super.dispose();
  }

  /// Returns questions from the hardcoded bank filtered to the player's paths.
  /// Falls back to the full bank if no matching questions exist.
  List<CombatQuestion> _classFilteredFallback(PlayerData player) {
    final filtered = CombatQuestionBank.all
        .where((q) =>
            q.classTag == player.mainPath ||
            q.classTag == player.sidePath ||
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
        title: Text('Abandon the Trial?', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Text(
          'You will retreat from this enlightenment and lose ${CombatService.fleePenaltyXp} Qi.',
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
                Column(
                  children: [
                    _buildTopBar(ctx, cs),
                    MonsterHpBar(
                      fraction: _service!.monsterHpFraction,
                      current: _service!.monsterCurrentHp,
                      max: _service!.monsterMaxHp,
                      monsterName: _service!.monsterName,
                    ),
                    Expanded(child: _buildArena(cs)),
                    // Timer row — remounts fresh each round via ValueKey
                    SizedBox(
                      height: 44,
                      child: _service!.isPlayerTurn && !_service!.isFightOver
                          ? Center(
                              child: CountdownTimer(
                                key: ValueKey(_service!.currentRound),
                                seconds: 15,
                                onTimeout: () =>
                                    _service!.answerQuestion(-1),
                              ),
                            )
                          : null,
                    ),
                    PlayerHpBar(
                      fraction: _service!.playerHpFraction,
                      current: _service!.playerCurrentHp,
                      max: _service!.playerMaxHp,
                    ),
                    QuestionCard(
                      questionText: _service!.currentQuestion.questionText,
                      options: _service!.currentQuestion.options,
                      correctIndex: _service!.currentQuestion.correctIndex,
                      selectedIndex: _service!.selectedAnswerIndex,
                      isEnabled:
                          _service!.isPlayerTurn && !_service!.isFightOver,
                      onAnswer: _service!.answerQuestion,
                      showWeaponHint: _hasWeaponHint,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                if (_service!.isFightOver) _buildResultOverlay(ctx, cs),
              ],
            );
          },
        ),
      ),
    ),
  );
  }

  // ── Top bar ────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _service!.canFlee ? _onFlee : null,
            child: Icon(
              Icons.arrow_back_ios,
              color: cs.onSurface.withValues(
                alpha: _service!.canFlee ? 0.4 : 0.15,
              ),
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            'ENLIGHTENMENT TRIAL',
            style: GoogleFonts.cinzel(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _service!.canFlee ? _onFlee : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  // ── Arena ──────────────────────────────────────────────────

  Widget _buildArena(ColorScheme cs) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Beast icon
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.psychology,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
          ),
          // Damage to beast (correct answer)
          if (_service!.lastDamageToMonster != null)
            Positioned(
              top: 0,
              child: Text(
                '-${_service!.lastDamageToMonster}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Damage to player
          if (_service!.lastDamageToPlayer != null)
            Positioned(
              bottom: 0,
              child: Text(
                '-${_service!.lastDamageToPlayer} VITALITY',
                style: TextStyle(
                  color: (_service!.wasLastAnswerCorrect ?? true)
                      ? Colors.orange
                      : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Result overlay ─────────────────────────────────────────

  Widget _buildResultOverlay(BuildContext context, ColorScheme cs) {
    final isVictory = _service!.result == CombatResult.victory;
    final isFled = _service!.result == CombatResult.fled;

    final title = isVictory
        ? 'COMPREHENDED'
        : isFled
            ? 'RETREATED'
            : 'DEFEATED';

    final subtitle = isVictory
        ? 'The beast has been vanquished.'
        : isFled
            ? 'You escaped the trial.'
            : 'The beast proved too powerful.';

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

    // Qi / Vitality delta display
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
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
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
                      color: isSaving
                          ? color.withValues(alpha: 0.5)
                          : color,
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
    );
  }
}
