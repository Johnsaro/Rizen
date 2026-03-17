import 'package:flutter/foundation.dart';
import '../models/combat_question.dart';
import '../models/combat_session.dart';

class CombatService extends ChangeNotifier {
  final List<CombatQuestion> _questions;
  final String monsterName;
  final String monsterId;
  final int monsterMaxHp;
  final int _playerMaxHp;
  final double _playerStartXP;
  final int _playerLevel;

  // Wrong answer / timeout — monster attacks for this much
  static const int _monsterDamageWrong = 30;

  // XP deducted from player on flee — exposed so the UI can display it
  static const int fleePenaltyXp = 50;

  int monsterCurrentHp;
  int playerCurrentHp;
  int _currentRound = 0;
  bool isPlayerTurn = true;
  bool isFightOver = false;
  CombatResult? result;

  // Feedback state — set during the 700ms window, cleared on next question
  int? selectedAnswerIndex;
  bool? wasLastAnswerCorrect;
  int? lastDamageToMonster;
  int? lastDamageToPlayer;

  int _correctAnswers = 0;
  String _lastCorrectClassTag = 'Any';
  int? _defeatXpLoss;

  bool _disposed = false;

  CombatService({
    required List<CombatQuestion> questions,
    required this.monsterName,
    required this.monsterId,
    required this.monsterMaxHp,
    required int playerHp,
    required int playerMaxHp,
    required double playerXP,
    required int playerLevel,
  })  : _questions = List.from(questions)..shuffle(),
        monsterCurrentHp = monsterMaxHp,
        playerCurrentHp = playerHp,
        _playerMaxHp = playerMaxHp,
        _playerStartXP = playerXP,
        _playerLevel = playerLevel;

  // ── Getters ─────────────────────────────────────────────────

  CombatQuestion get currentQuestion =>
      _questions[_currentRound % _questions.length];

  /// Monotonically increasing round counter — used as ValueKey for timer resets.
  int get currentRound => _currentRound;

  double get monsterHpFraction =>
      (monsterCurrentHp / monsterMaxHp).clamp(0.0, 1.0);

  double get playerHpFraction =>
      (playerCurrentHp / _playerMaxHp).clamp(0.0, 1.0);

  int get playerMaxHp => _playerMaxHp;

  /// XP earned this fight: 20 XP per correct answer.
  int get xpReward => _correctAnswers * 20;

  /// Class tag of the most recent correct answer (used by GameService to route XP).
  String get combatClassTag => _lastCorrectClassTag;

  /// False when monster HP ≤ 25% — player is locked in and must finish the fight.
  bool get canFlee => monsterHpFraction > 0.25 && !isFightOver;

  /// XP loss on defeat — computed once at fight-end from the player snapshot
  /// captured at construction. Zero until the fight ends in defeat.
  int get defeatXpLoss => _defeatXpLoss ?? 0;

  // ── Fight logic ─────────────────────────────────────────────

  /// Call with the index the player tapped (0–3), or -1 for a timer timeout.
  Future<void> answerQuestion(int chosenIndex) async {
    if (!isPlayerTurn || isFightOver || _disposed) return;

    isPlayerTurn = false;

    final question = currentQuestion;
    final correct =
        chosenIndex >= 0 && chosenIndex == question.correctIndex;

    selectedAnswerIndex = chosenIndex;
    wasLastAnswerCorrect = correct;

    if (correct) {
      // Correct — player deals damage, monster does not counter
      _correctAnswers++;
      _lastCorrectClassTag = question.classTag;
      lastDamageToMonster = question.baseDamage;
      monsterCurrentHp =
          (monsterCurrentHp - question.baseDamage).clamp(0, monsterMaxHp);
      lastDamageToPlayer = null;
    } else {
      // Wrong / timeout — monster attacks, player takes full damage
      lastDamageToMonster = null;
      lastDamageToPlayer = _monsterDamageWrong;
      playerCurrentHp =
          (playerCurrentHp - _monsterDamageWrong).clamp(0, _playerMaxHp);
    }

    _safeNotify(); // Show feedback + updated HP bars

    await Future.delayed(const Duration(milliseconds: 700));
    if (_disposed) return;

    // Check outcomes after feedback window
    if (monsterCurrentHp <= 0) {
      _endFight(CombatResult.victory);
      return;
    }
    if (playerCurrentHp <= 0) {
      _endFight(CombatResult.defeat);
      return;
    }

    // Advance to next question
    _currentRound++;
    selectedAnswerIndex = null;
    wasLastAnswerCorrect = null;
    lastDamageToMonster = null;
    lastDamageToPlayer = null;
    isPlayerTurn = true;
    _safeNotify();
  }

  void flee() {
    if (isFightOver || _disposed) return;
    _endFight(CombatResult.fled);
  }

  // ── Private ─────────────────────────────────────────────────

  void _endFight(CombatResult r) {
    isFightOver = true;
    isPlayerTurn = false;
    result = r;
    if (r == CombatResult.defeat) {
      final raw = (_playerStartXP * (0.05 + _playerLevel * 0.005)).floor();
      _defeatXpLoss = raw.clamp(0, 500);
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
