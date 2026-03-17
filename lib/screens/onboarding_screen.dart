import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../main_shell.dart';
import '../theme/night_guild_background.dart';

// Available paths — mapping IT domains to cultivation paths for display
String _displayPathName(String className) {
  const map = {
    'Sec Analyst': 'Shadow Arts',
    'Game Developer': 'Realm Architect',
    'Web Developer': 'Formation Master',
    'Mobile Developer': 'Artifact Refiner',
  };
  return map[className] ?? className;
}

const _availableClasses = [
  ('Mobile Developer', 'UI/UX, Cross-Platform, Tool Crafting'),
  ('Game Developer', 'World Creation, Logic, Math'),
  ('Web Developer', 'Arrays, Frameworks, Scaling'),
  ('Sec Analyst', 'Infiltration, Recon, Stealth'),
];

class _Msg {
  final String text;
  final bool isGM;
  _Msg(this.text, {this.isGM = true});
}

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

  bool _showNameInput = false;
  bool _showDescInput = false;
  bool _showClassAccept = false;
  bool _showBeginButton = false;
  bool _showEnterButton = false;
  bool _inputEnabled = true;
  bool _isSaving = false;

  String _playerName = '';
  String _mainClass = '';
  String _sideClass = '';

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

  // ── helpers ──────────────────────────────────────────

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _add(String text, {bool isGM = true}) {
    setState(() => _messages.add(_Msg(text, isGM: isGM)));
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

  String _detectClass(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('hack') ||
        d.contains('pentest') ||
        d.contains('security') ||
        d.contains('ctf') ||
        d.contains('cyber')) {
      return 'Sec Analyst';
    }
    if (d.contains('game') ||
        d.contains('unity') ||
        d.contains('unreal') ||
        d.contains('godot')) {
      return 'Game Developer';
    }
    if (d.contains('mobile') ||
        d.contains('flutter') ||
        d.contains('android') ||
        d.contains('ios')) {
      return 'Mobile Developer';
    }
    if (d.contains('web') ||
        d.contains('frontend') ||
        d.contains('react') ||
        d.contains('css') ||
        d.contains('html')) {
      return 'Web Developer';
    }
    return 'Web Developer'; // default
  }

  String _detectSideClass(String desc, String mainClass) {
    final d = desc.toLowerCase();
    if (mainClass != 'Sec Analyst' &&
        (d.contains('hack') || d.contains('security') || d.contains('pentest'))) {
      return 'Sec Analyst';
    }
    if (mainClass != 'Mobile Developer' &&
        (d.contains('mobile') ||
            d.contains('flutter') ||
            d.contains('android'))) {
      return 'Mobile Developer';
    }
    if (mainClass != 'Game Developer' &&
        (d.contains('game') || d.contains('unity'))) {
      return 'Game Developer';
    }
    if (mainClass != 'Web Developer' &&
        (d.contains('web') || d.contains('frontend') || d.contains('react'))) {
      return 'Web Developer';
    }
    return mainClass == 'Sec Analyst' ? 'Web Developer' : 'Sec Analyst';
  }

  String _gmFlavorText(String desc) {
    final main = _detectClass(desc);
    if (main == 'Sec Analyst') return 'A shadow walker. One who moves unseen through the void.';
    if (main == 'Game Developer') {
      return 'You architect entire realms for others to inhabit. A creator\'s spark.';
    }
    if (main == 'Mobile Developer') {
      return 'You refine artifacts that the world carries in their palms.';
    }
    return 'The web is your tapestry. You weave the formations that bind information.';
  }

  // ── onboarding phases ────────────────────────────────

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
    _runClassDiscovery();
  }

  Future<void> _runClassDiscovery() async {
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
    _mainClass = _detectClass(desc);
    _sideClass = _detectSideClass(desc, _mainClass);
    _runClassAssignment(desc);
  }

  Future<void> _runClassAssignment(String desc) async {
    await _delay(800);
    _add('Analysis complete.');
    await _delay(1000);
    _add(_gmFlavorText(desc));
    await _delay(1600);
    _add(
      'Your Primary Dao is ${_displayPathName(_mainClass)}. ${_displayPathName(_sideClass)} serves as your secondary path.',
    );
    await _delay(1000);
    setState(() => _showClassAccept = true);
  }

  void _onClassAccepted() {
    setState(() => _showClassAccept = false);
    _add('Synchronized.', isGM: false);
    _runCharacterCreated();
  }

  void _onChangeClass() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _ClassPicker(
        currentMain: _mainClass,
        onSelected: (main, side) {
          setState(() {
            _mainClass = main;
            _sideClass = side;
          });
          Navigator.pop(sheetContext);
        },
      ),
    );
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

  Future<void> _onEnterGuild() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    gameService.errorNotifier.value = null;

    final player = PlayerData(
      name: _playerName,
      mainClass: _mainClass,
      sideClass: _sideClass,
    );

    await gameService.updatePlayer(player, onboardingComplete: true);

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  // ── build ─────────────────────────────────────────────

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
        mainAxisAlignment: isGM
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isGM ? cs.surface : cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isGM ? 4 : 12),
                  topRight: Radius.circular(isGM ? 12 : 4),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                ),
                border: Border.all(
                  color: isGM ? cs.outline : cs.primary.withValues(alpha: 0.3),
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
                  fontStyle: msg.text == '...'
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    if (_showClassAccept) return _buildClassAccept(cs);
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

  Widget _buildClassAccept(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Path summary
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
                _classChip('PRIMARY DAO', _displayPathName(_mainClass), cs),
                const SizedBox(height: 6),
                _classChip('SECONDARY DAO', _displayPathName(_sideClass), cs),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _onClassAccepted,
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
                  onTap: _onChangeClass,
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

  Widget _classChip(String tag, String className, ColorScheme cs) {
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
          className,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ColorScheme cs, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
            onTap: _isSaving ? null : _onEnterGuild,
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

// ── Path picker bottom sheet ────────────────────────────

class _ClassPicker extends StatefulWidget {
  final String currentMain;
  final void Function(String main, String side) onSelected;

  const _ClassPicker({required this.currentMain, required this.onSelected});

  @override
  State<_ClassPicker> createState() => _ClassPickerState();
}

class _ClassPickerState extends State<_ClassPicker> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMain;
  }

  String _defaultSide(String main) {
    return main == 'Sec Analyst' ? 'Web Developer' : 'Sec Analyst';
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
            'CHOOSE YOUR PRIMARY DAO',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ..._availableClasses.map((c) {
            final isSelected = _selected == c.$1;
            return GestureDetector(
              onTap: () => setState(() => _selected = c.$1),
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
                            _displayPathName(c.$1),
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
                            c.$2,
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
            onTap: () => widget.onSelected(_selected, _defaultSide(_selected)),
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
