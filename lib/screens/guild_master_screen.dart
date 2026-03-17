import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/quest.dart';
import '../services/guild_master_service.dart';
import '../theme/night_guild_background.dart';
import '../theme/rank_colors.dart';
import '../theme/rizen_colors.dart';

// ── Message model ─────────────────────────────────────────

enum _MsgType { gmChat, playerChat, questCard, validationResult }

class _ChatMessage {
  final _MsgType type;
  final String text;
  final Quest? quest;
  final bool? approved;
  final int? xpAwarded;
  bool questAccepted = false;

  _ChatMessage({
    required this.type,
    this.text = '',
    this.quest,
    this.approved,
    this.xpAwarded,
  });
}

// ── Screen ────────────────────────────────────────────────

class GuildMasterScreen extends StatefulWidget {
  const GuildMasterScreen({super.key});

  @override
  State<GuildMasterScreen> createState() => _GuildMasterScreenState();
}

class _GuildMasterScreenState extends State<GuildMasterScreen> {
  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _isThinking = false;
  bool _sessionEnded = false;
  int _playerTurnCount = 0;
  late GuildMasterService _service;

  @override
  void initState() {
    super.initState();
    _service = GuildMasterService();
    _messages.add(
      _ChatMessage(
        type: _MsgType.gmChat,
        text: 'Synchronization established. What have you discovered in the physical realm?',
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isThinking || _sessionEnded) return;

    if (_playerTurnCount >= 20) {
      setState(() {
        _sessionEnded = true;
        _messages.add(_ChatMessage(
          type: _MsgType.gmChat,
          text: 'Synchronization threshold reached. The System must recalibrate. Return after the next celestial reset.',
        ));
      });
      _scrollToBottom();
      return;
    }

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(type: _MsgType.playerChat, text: text));
      _isThinking = true;
    });
    _scrollToBottom();

    final historySnapshot = List<Map<String, String>>.from(_history);
    _history.add({'role': 'user', 'content': text});
    _playerTurnCount++;

    try {
      final gmResp = await _service.sendMessage(
        text,
        historySnapshot,
        playerNotifier.value,
        questNotifier.value,
      );
      _history.add({'role': 'assistant', 'content': gmResp.message});

      if (!mounted) return;

      Quest? newGuildQuest;
      Quest? validatedQuest;

      setState(() {
        _isThinking = false;
        _messages.add(
          _ChatMessage(type: _MsgType.gmChat, text: gmResp.message),
        );

        if (gmResp.action == 'create_quest' && gmResp.quest != null) {
          _messages.add(
            _ChatMessage(type: _MsgType.questCard, quest: gmResp.quest),
          );
          final q = gmResp.quest!;
          if (!guildBoardNotifier.value.any((b) => b.id == q.id)) {
            newGuildQuest = q;
          }
        } else if (gmResp.action == 'validate_quest') {
          final matchedQuest = questNotifier.value
              .where((q) => q.id == gmResp.questId)
              .firstOrNull;
          final approved = gmResp.approved ?? false;

          if (!approved || matchedQuest == null) {
            _messages.add(
              _ChatMessage(
                type: _MsgType.validationResult,
                approved: false,
                quest: matchedQuest,
              ),
            );
          } else {
            validatedQuest = matchedQuest;
          }
        }
      });

      if (newGuildQuest != null) {
        await gameService.addGuildBoardQuests([newGuildQuest!]);
      }
      if (validatedQuest != null) {
        await gameService.completeQuest(validatedQuest!);
        if (mounted) {
          final wasCompleted = !questNotifier.value.any((q) => q.id == validatedQuest!.id);
          setState(() {
            _messages.add(
              _ChatMessage(
                type: _MsgType.validationResult,
                approved: wasCompleted,
                xpAwarded: wasCompleted ? validatedQuest!.xpReward : null,
                quest: validatedQuest,
              ),
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('GM error: $e');
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(
          _ChatMessage(
            type: _MsgType.gmChat,
            text: 'The System connection is unstable. Attempt synchronization again.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _acceptQuest(Quest quest, int msgIndex) async {
    if (questNotifier.value.any((q) => q.id == quest.id)) return;
    setState(() => _messages[msgIndex].questAccepted = true);
    await gameService.acceptQuest(quest);
    // If the write rolled back, the quest won't be in the notifier — revert the flag
    if (mounted && !questNotifier.value.any((q) => q.id == quest.id)) {
      setState(() => _messages[msgIndex].questAccepted = false);
    }
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rz = Theme.of(context).extension<RizenColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(cs),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isThinking && i == _messages.length) {
                      return _buildTypingIndicator(cs);
                    }
                    return _buildItem(_messages[i], i, cs, rz);
                  },
                ),
              ),
              _buildInput(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios,
              color: cs.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: cs.secondary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'THE SYSTEM',
            style: GoogleFonts.cinzel(
              color: cs.secondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    _ChatMessage msg,
    int index,
    ColorScheme cs,
    RizenColors rz,
  ) {
    switch (msg.type) {
      case _MsgType.gmChat:
        return _buildGmBubble(msg.text, cs);
      case _MsgType.playerChat:
        return _buildPlayerBubble(msg.text, cs);
      case _MsgType.questCard:
        return _buildQuestCard(msg, index, cs, rz);
      case _MsgType.validationResult:
        return _buildValidationCard(msg, cs, rz);
    }
  }

  Widget _buildGmBubble(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: cs.primary, size: 14),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBubble(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                text,
                style: TextStyle(color: cs.primary, fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(
    _ChatMessage msg,
    int index,
    ColorScheme cs,
    RizenColors rz,
  ) {
    final quest = msg.quest!;
    final rc = rankColor(quest.rank);
    final accepted = msg.questAccepted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 36),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accepted
                ? rz.xp.withValues(alpha: 0.35)
                : cs.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: (accepted ? rz.xp : cs.primary).withValues(alpha: 0.06),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rc.withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Text(
                        quest.rank,
                        style: TextStyle(
                          color: rc,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
                          '${quest.xpReward} Qi  ·  Trial  ·  ${quest.classTag}',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                quest.description,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            if (!accepted)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _acceptQuest(quest, index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            'ACCEPT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42,
                      color: cs.outline.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'IGNORE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.3),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: rz.xp.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: rz.xp.withValues(alpha: 0.2)),
                  ),
                ),
                child: Center(
                  child: Text(
                    'TRIAL ACCEPTED',
                    style: TextStyle(
                      color: rz.xp,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResult(
    _ChatMessage msg,
    ColorScheme cs,
    RizenColors rz,
  ) {
    final approved = msg.approved ?? false;
    final color = approved ? rz.xp : rz.danger;
    final canRetry = !approved && msg.quest != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 36),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Icon(
              approved ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    approved ? 'TRIAL COMPLETE' : 'INSUFFICIENT',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  if (approved && msg.xpAwarded != null && msg.xpAwarded! > 0)
                    Text(
                      '+${msg.xpAwarded} Qi awarded',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (canRetry)
              GestureDetector(
                onTap: () => _retryValidation(msg.quest!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RE-ANALYZE',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildValidationCard(
    _ChatMessage msg,
    ColorScheme cs,
    RizenColors rz,
  ) => _buildValidationResult(msg, cs, rz);

  Future<void> _retryValidation(Quest quest) async {
    setState(() => _isThinking = true);
    try {
      await gameService.completeQuest(quest);
      if (!mounted) return;
      final wasCompleted = !questNotifier.value.any((q) => q.id == quest.id);
      setState(() {
        _isThinking = false;
        _messages.add(
          _ChatMessage(
            type: _MsgType.validationResult,
            approved: wasCompleted,
            xpAwarded: wasCompleted ? quest.xpReward : null,
            quest: quest,
          ),
        );
      });
    } catch (e) {
      debugPrint('Retry validation error: $e');
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(
          _ChatMessage(
            type: _MsgType.gmChat,
            text: 'Synchronization error. Try again.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Widget _buildTypingIndicator(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.auto_awesome, color: cs.primary, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(
                  color: cs.primary.withValues(alpha: 0.5),
                  delay: Duration.zero,
                ),
                const SizedBox(width: 4),
                _PulseDot(
                  color: cs.primary.withValues(alpha: 0.5),
                  delay: const Duration(milliseconds: 150),
                ),
                const SizedBox(width: 4),
                _PulseDot(
                  color: cs.primary.withValues(alpha: 0.5),
                  delay: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_isThinking && !_sessionEnded,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Transmit intent...',
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (_isThinking || _sessionEnded)
                    ? cs.tertiary.withValues(alpha: 0.3)
                    : cs.tertiary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: (_isThinking || _sessionEnded)
                    ? null
                    : [
                        BoxShadow(
                          color: cs.tertiary.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot for typing indicator ─────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  final Duration delay;
  const _PulseDot({required this.color, required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
