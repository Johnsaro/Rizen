import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../models/sect_path.dart';
import '../main_shell.dart';
import '../theme/night_guild_background.dart';
import '../services/supabase_service.dart';
import '../services/ai_exam_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Sect / class display helpers ──────────────────────────

/// Display name is now the same as the stored path name (V2 native).
String _displaySectName(String pathName) => pathName;

const _availableSects = [
  ('Shadow Arts', 'Cybersecurity — Infiltration, Recon, Defense'),
  ('Realm Architect', 'Game Dev — World Creation, Logic, Math'),
  ('Formation Master', 'Web Dev — Arrays, Frameworks, Scaling'),
  ('Artifact Refiner', 'Mobile Dev — UI/UX, Cross-Platform, Tool Crafting'),
];

// ── Chat message model ──────────────────────────────────

class _Msg {
  final String text;
  final bool isGM;
  _Msg(this.text, {this.isGM = true});
}

// ── Onboarding screen ───────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<_Msg> _messages = [];
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _scroll = ScrollController();

  // ── UI state flags ──
  bool _showNameInput = false;
  bool _showDescInput = false;
  bool _showSectAccept = false;
  bool _showPathPicker = false;
  bool _showExamQuestion = false;
  bool _showExamResult = false;
  bool _showBeginButton = false;
  bool _showEnterButton = false;
  bool _showRetryOrSwitch = false;
  bool _inputEnabled = true;
  bool _isSaving = false;
  bool _isLoadingExam = false;

  // ── Player data ──
  String _playerName = '';
  String _mainClass = '';   // V2 path name (e.g. 'Shadow Arts')
  String _sideClass = '';
  String _sect = '';        // display name (e.g. 'Shadow Arts')
  String _activePath = '';  // path name (e.g. 'Infiltrator')
  String _activePathId = '';

  // ── Shadow Arts path data ──
  List<SectPath> _sectPaths = [];
  SectPath? _selectedPath;

  // ── Exam state ──
  List<ExamQuestion> _examQuestions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _selectedChoiceIndex = -1;
  bool _answerRevealed = false;

  @override
  void initState() {
    super.initState();
    _runArrival();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _add(String text, {bool isGM = true}) {
    setState(() => _messages.add(_Msg(text, isGM: isGM)));
    _scrollToBottom();
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

  String _detectSect(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('hack') ||
        d.contains('pentest') ||
        d.contains('security') ||
        d.contains('ctf') ||
        d.contains('cyber') ||
        d.contains('red team') ||
        d.contains('blue team')) {
      return 'Shadow Arts';
    }
    if (d.contains('game') ||
        d.contains('unity') ||
        d.contains('unreal') ||
        d.contains('godot')) {
      return 'Realm Architect';
    }
    if (d.contains('mobile') ||
        d.contains('flutter') ||
        d.contains('android') ||
        d.contains('ios')) {
      return 'Artifact Refiner';
    }
    if (d.contains('web') ||
        d.contains('frontend') ||
        d.contains('react') ||
        d.contains('css') ||
        d.contains('html')) {
      return 'Formation Master';
    }
    return 'Formation Master'; // default
  }

  String _detectSideClass(String mainPath) {
    return mainPath == 'Shadow Arts' ? 'Formation Master' : 'Shadow Arts';
  }

  String _gmFlavorText(String sect) {
    if (sect == 'Shadow Arts') {
      return 'A shadow walker. One who moves unseen through the void.';
    }
    if (sect == 'Realm Architect') {
      return 'You architect entire realms for others to inhabit. A creator\'s spark.';
    }
    if (sect == 'Artifact Refiner') {
      return 'You refine artifacts that the world carries in their palms.';
    }
    return 'The web is your tapestry. You weave the formations that bind information.';
  }

  bool get _isShadowArts => _sect == 'Shadow Arts';

  // ── Phase: Arrival ────────────────────────────────────

  Future<void> _runArrival() async {
    await _delay(800);
    _add('...');
    await _delay(1200);
    _add('[SYSTEM] New consciousness detected. Binding initiated.');
    await _delay(1500);
    _add('Few survive the synchronization process. Most... fade.');
    await _delay(1600);
    _add('Define your identifier.');
    setState(() => _showNameInput = true);
  }

  void _onNameSubmit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _playerName = name;
      _showNameInput = false;
      _inputEnabled = false;
    });
    _add(name, isGM: false);
    _runSectDiscovery();
  }

  // ── Phase: Sect Discovery ─────────────────────────────

  Future<void> _runSectDiscovery() async {
    await _delay(800);
    _add('$_playerName.');
    await _delay(1200);
    _add('Analyze your real-world affinities. What is your primary focus?');
    setState(() {
      _showDescInput = true;
      _inputEnabled = true;
    });
  }

  void _onDescSubmit() {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    setState(() {
      _showDescInput = false;
      _inputEnabled = false;
    });
    _add(desc, isGM: false);

    _sect = _detectSect(desc);
    _mainClass = _sect;
    _sideClass = _detectSideClass(_mainClass);

    debugPrint('[Onboarding] Sect detected: $_sect | mainPath: $_mainClass | sidePath: $_sideClass | input: "$desc"');

    _runSectAssignment();
  }

  Future<void> _runSectAssignment() async {
    await _delay(800);
    _add('Analysis complete.');
    await _delay(1000);
    _add(_gmFlavorText(_sect));
    await _delay(1600);

    if (_isShadowArts) {
      _add('Your affinity aligns with the $_sect sect.');
    } else {
      _add(
        'Your Primary Dao is $_sect. ${_displaySectName(_sideClass)} serves as your secondary path.',
      );
    }
    await _delay(1000);
    setState(() => _showSectAccept = true);
  }

  void _onSectAccepted() {
    setState(() => _showSectAccept = false);
    _add('Synchronized.', isGM: false);

    debugPrint('[Onboarding] Sect accepted: $_sect | isShadowArts: $_isShadowArts');

    if (_isShadowArts) {
      _runPathSelection();
    } else {
      _runCharacterCreated();
    }
  }

  void _onChangeSect() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _SectPicker(
        currentSect: _sect,
        onSelected: (sect) {
          setState(() {
            _sect = sect;
            _mainClass = sect;
            _sideClass = _detectSideClass(_mainClass);
          });
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  // ── Phase: Path Selection (Shadow Arts only) ──────────

  Future<void> _runPathSelection() async {
    await _delay(800);
    _add('The Shadow Arts sect has five paths. Each demands a different discipline.');
    await _delay(1200);

    // Fetch paths from Supabase
    try {
      _sectPaths = await SupabaseService.loadSectPaths('Shadow Arts');
    } catch (e) {
      _add('[SYSTEM ERROR] Could not reach the sect archives. Using default paths.');
      // Fallback — shouldn't happen if SQL was run
      _sectPaths = [];
    }

    if (_sectPaths.isEmpty) {
      _add('The archives are sealed. Proceed without a path for now.');
      _runCharacterCreated();
      return;
    }

    await _delay(800);
    _add('Choose your path, cultivator.');
    setState(() => _showPathPicker = true);
  }

  void _onPathSelected(SectPath path) {
    setState(() {
      _selectedPath = path;
      _showPathPicker = false;
      _activePath = path.pathName;
      _activePathId = path.id;
    });
    _add('${path.pathName} — ${path.domain}.', isGM: false);
    _runEntryExam();
  }

  // ── Phase: Entry Exam (AI-generated) ──────────────────

  Future<void> _runEntryExam() async {
    await _delay(800);
    _add('Before you walk the ${_selectedPath!.pathName} path, you must prove basic understanding.');
    await _delay(1200);
    _add('Five questions. Answer three correctly to enter.');
    await _delay(1000);

    setState(() => _isLoadingExam = true);
    _add('Preparing your trial...');

    try {
      _examQuestions = await AiExamService.generateEntryExam(
        pathName: _selectedPath!.pathName,
        domain: _selectedPath!.domain,
      );
    } on ExamGenerationException catch (e) {
      setState(() => _isLoadingExam = false);
      _add('[SYSTEM ERROR] ${e.message}');
      await _delay(1000);
      setState(() => _showRetryOrSwitch = true);
      return;
    } catch (_) {
      setState(() => _isLoadingExam = false);
      _add('[SYSTEM ERROR] The exam could not be prepared. Try again.');
      await _delay(1000);
      setState(() => _showRetryOrSwitch = true);
      return;
    }

    setState(() {
      _isLoadingExam = false;
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
    });

    await _delay(800);
    _showNextQuestion();
  }

  void _showNextQuestion() {
    if (_currentQuestionIndex >= _examQuestions.length) {
      _runExamResults();
      return;
    }

    final q = _examQuestions[_currentQuestionIndex];
    _add('Question ${_currentQuestionIndex + 1}/${_examQuestions.length}: ${q.question}');

    setState(() {
      _selectedChoiceIndex = -1;
      _answerRevealed = false;
      _showExamQuestion = true;
    });
  }

  void _onChoiceSelected(int index) {
    if (_answerRevealed) return;
    setState(() => _selectedChoiceIndex = index);
  }

  void _onSubmitAnswer() {
    if (_selectedChoiceIndex < 0 || _answerRevealed) return;

    final q = _examQuestions[_currentQuestionIndex];
    final isCorrect = _selectedChoiceIndex == q.correctIndex;
    final letter = ['A', 'B', 'C', 'D'][_selectedChoiceIndex];

    _add(letter, isGM: false);

    if (isCorrect) {
      _correctAnswers++;
    }

    setState(() => _answerRevealed = true);
  }

  void _onNextQuestion() {
    setState(() {
      _showExamQuestion = false;
      _currentQuestionIndex++;
    });

    // Short delay before next question
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showNextQuestion();
    });
  }

  // ── Phase: Exam Results ───────────────────────────────

  void _runExamResults() {
    final passed = _correctAnswers >= 3;

    if (passed) {
      _add('$_correctAnswers out of ${_examQuestions.length}. Sufficient.');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        _add('You are accepted into the $_activePath path of the Shadow Arts.');
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() => _showExamResult = true);
        });
      });
    } else {
      _add('$_correctAnswers out of ${_examQuestions.length}. Insufficient.');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        _add('The path demands more preparation. You may try again or choose another way.');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() => _showRetryOrSwitch = true);
        });
      });
    }
  }

  void _onRetryExam() {
    setState(() => _showRetryOrSwitch = false);
    _add('I will try again.', isGM: false);
    _runEntryExam();
  }

  void _onSwitchPath() {
    setState(() {
      _showRetryOrSwitch = false;
      _selectedPath = null;
      _activePath = '';
      _activePathId = '';
    });
    _add('I choose a different path.', isGM: false);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _add('Choose your path, cultivator.');
      setState(() => _showPathPicker = true);
    });
  }

  // ── Phase: Exam Passed → Character Created ────────────

  void _onExamPassed() {
    setState(() => _showExamResult = false);
    _runCharacterCreated();
  }

  Future<void> _runCharacterCreated() async {
    await _delay(800);
    _add('The path is set.');
    await _delay(1200);
    _add(
      'Your physical actions will now fuel your cultivation base. Stagnation leads to decay.',
    );
    await _delay(1500);
    setState(() => _showBeginButton = true);
  }

  void _onBeginPressed() {
    setState(() => _showBeginButton = false);
    _runFirstQuest();
  }

  Future<void> _runFirstQuest() async {
    await _delay(600);
    _add('A final mandate.');
    await _delay(1200);
    _add('Consistency is the foundation of power.');
    await _delay(1500);
    setState(() => _showEnterButton = true);
    await _delay(200);
    _add('Ascend with resolve, cultivator.');
  }

  // ── Save & Enter ──────────────────────────────────────

  Future<void> _onEnterSect() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    gameService.errorNotifier.value = null;

    final player = PlayerData(
      name: _playerName,
      mainPath: _mainClass,
      sidePath: _sideClass,
      sect: _isShadowArts ? 'Shadow Arts' : '',
      activePath: _activePath,
    );

    debugPrint('[Onboarding] SAVING profile → name: $_playerName | mainPath: $_mainClass | sidePath: $_sideClass | sect: ${_isShadowArts ? "Shadow Arts" : "(none)"} | path: $_activePath');

    await gameService.updatePlayer(
      player,
      onboardingComplete: true,
      originPlatform: 'flutter',
    );

    debugPrint('[Onboarding] Save result → error: ${gameService.errorNotifier.value}');

    if (!mounted) return;

    if (gameService.errorNotifier.value != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not synchronize with the System — check your connection.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // For Shadow Arts: create player_path + grant starter weapon
    if (_isShadowArts && _activePathId.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create player path at Rank F
        await SupabaseService.createPlayerPath(userId, _activePathId);

        // Grant starter weapon (rank F, cost 0 = free)
        final weapons =
            await SupabaseService.loadWeaponsForPath(_activePath);
        final starter = weapons.where((w) => w.isFree).toList();
        if (starter.isNotEmpty) {
          await SupabaseService.grantWeapon(
            userId,
            starter.first.id,
            equip: true,
          );
          // Update player with equipped weapon name
          final updatedPlayer = player.copyWith(
            equippedWeapon: starter.first.name,
          );
          await gameService.updatePlayer(updatedPlayer, originPlatform: 'flutter');
        }
      } catch (e) {
        // Non-critical — path/weapon can be set up later
        debugPrint('Onboarding path/weapon setup failed: $e');
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMessage(_messages[i], cs),
                ),
              ),
              _buildInputArea(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.15),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.auto_awesome, color: cs.secondary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'THE SYSTEM',
            style: TextStyle(
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

  Widget _buildMessage(_Msg msg, ColorScheme cs) {
    final isGM = msg.isGM;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isGM ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGM) ...[
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
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isGM ? cs.surface : cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isGM ? 4 : 12),
                  topRight: Radius.circular(isGM ? 12 : 4),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                ),
                border: Border.all(
                  color:
                      isGM ? cs.outline : cs.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isGM
                      ? cs.onSurface.withValues(alpha: 0.85)
                      : cs.primary,
                  fontSize: 14,
                  height: 1.5,
                  fontStyle:
                      msg.text == '...' ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input area (bottom) ───────────────────────────────

  Widget _buildInputArea(ColorScheme cs) {
    if (_showNameInput) {
      return _buildTextInput(cs, _nameCtrl, 'identifier...', _onNameSubmit);
    }
    if (_showDescInput) {
      return _buildTextInput(
        cs,
        _descCtrl,
        'describe your affinities...',
        _onDescSubmit,
        multiline: true,
      );
    }
    if (_showSectAccept) return _buildSectAccept(cs);
    if (_showPathPicker) return _buildPathPicker(cs);
    if (_isLoadingExam) return _buildLoading(cs, 'Generating exam...');
    if (_showExamQuestion) return _buildExamQuestionUI(cs);
    if (_showExamResult) return _buildExamPassedUI(cs);
    if (_showRetryOrSwitch) return _buildRetryOrSwitch(cs);
    if (_showBeginButton) {
      return _buildActionButton(cs, 'START YOUR ASCENSION', _onBeginPressed);
    }
    if (_showEnterButton) return _buildFirstQuest(cs);
    return const SizedBox(height: 16);
  }

  Widget _buildTextInput(
    ColorScheme cs,
    TextEditingController ctrl,
    String hint,
    VoidCallback onSubmit, {
    bool multiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              enabled: _inputEnabled,
              maxLines: multiline ? 4 : 1,
              minLines: 1,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onSubmitted: multiline ? null : (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sect accept / change ──────────────────────────────

  Widget _buildSectAccept(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tagChip('SECT', _sect, cs),
                if (!_isShadowArts) ...[
                  const SizedBox(height: 6),
                  _tagChip(
                    'SECONDARY',
                    _displaySectName(_sideClass),
                    cs,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _onSectAccepted,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'SYNCHRONIZE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _onChangeSect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Text(
                      'RE-ANALYZE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Path picker (Shadow Arts only) ────────────────────

  Widget _buildPathPicker(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHOOSE YOUR PATH',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: _sectPaths.map((path) {
                return GestureDetector(
                  onTap: () => _onPathSelected(path),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _pathIcon(path.pathName),
                              color: cs.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              path.pathName,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                path.domain,
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (path.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            path.description,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _pathIcon(String pathName) {
    const icons = {
      'Infiltrator': Icons.bug_report,
      'Phantom': Icons.lan,
      'Sentinel': Icons.shield,
      'Cipher': Icons.lock,
      'Seeker': Icons.search,
    };
    return icons[pathName] ?? Icons.explore;
  }

  // ── Exam question UI ──────────────────────────────────

  Widget _buildExamQuestionUI(ColorScheme cs) {
    final q = _examQuestions[_currentQuestionIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                'QUESTION ${_currentQuestionIndex + 1}/${_examQuestions.length}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '$_correctAnswers correct',
                style: TextStyle(
                  color: Colors.green.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Choices
          ...List.generate(q.choices.length, (i) {
            final letter = ['A', 'B', 'C', 'D'][i];
            final isSelected = _selectedChoiceIndex == i;
            final isCorrect = i == q.correctIndex;

            Color borderColor = cs.outline;
            Color bgColor = cs.surface;

            if (_answerRevealed) {
              if (isCorrect) {
                borderColor = Colors.green;
                bgColor = Colors.green.withValues(alpha: 0.1);
              } else if (isSelected && !isCorrect) {
                borderColor = Colors.red;
                bgColor = Colors.red.withValues(alpha: 0.1);
              }
            } else if (isSelected) {
              borderColor = cs.primary;
              bgColor = cs.primary.withValues(alpha: 0.08);
            }

            return GestureDetector(
              onTap: _answerRevealed ? null : () => _onChoiceSelected(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: (isSelected || (_answerRevealed && isCorrect))
                        ? 1.5
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.surface,
                        border: Border.all(
                          color: isSelected ? cs.primary : cs.outline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isSelected ? cs.primary : cs.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        q.choices[i],
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Explanation (shown after answer)
          if (_answerRevealed) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                q.explanation,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Submit / Next button
          GestureDetector(
            onTap: _answerRevealed
                ? _onNextQuestion
                : (_selectedChoiceIndex >= 0 ? _onSubmitAnswer : null),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: (_answerRevealed || _selectedChoiceIndex >= 0)
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _answerRevealed ? 'NEXT' : 'SUBMIT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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

  // ── Exam passed confirmation ──────────────────────────

  Widget _buildExamPassedUI(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_activePath Path Unlocked',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rank F  ·  $_correctAnswers/${_examQuestions.length} correct',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildActionButton(cs, 'CONTINUE', _onExamPassed),
        ],
      ),
    );
  }

  // ── Retry / Switch path ───────────────────────────────

  Widget _buildRetryOrSwitch(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _onRetryExam,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'RETRY EXAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _onSwitchPath,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  'SWITCH PATH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading indicator ─────────────────────────────────

  Widget _buildLoading(ColorScheme cs, String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────

  Widget _tagChip(String tag, String value, ColorScheme cs) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: cs.secondary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ColorScheme cs,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstQuest(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        children: [
          // First trial card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First Meditation',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tomorrow at 8AM  ·  50 Qi  ·  1 day',
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isSaving ? null : _onEnterSect,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isSaving
                    ? cs.primary.withValues(alpha: 0.5)
                    : cs.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!_isSaving)
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'ENTER THE SECT',
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
        ],
      ),
    );
  }
}

// ── Sect picker bottom sheet ────────────────────────────

class _SectPicker extends StatefulWidget {
  final String currentSect;
  final void Function(String sect) onSelected;

  const _SectPicker({required this.currentSect, required this.onSelected});

  @override
  State<_SectPicker> createState() => _SectPickerState();
}

class _SectPickerState extends State<_SectPicker> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSect;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHOOSE YOUR SECT',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ..._availableSects.map((s) {
            final isSelected = _selected == s.$1;
            return GestureDetector(
              onTap: () => setState(() => _selected = s.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.12)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$1,
                            style: TextStyle(
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.$2,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.35),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: cs.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => widget.onSelected(_selected),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'CONFIRM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
}
