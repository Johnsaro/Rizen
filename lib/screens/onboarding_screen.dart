import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../main_shell.dart';
import '../theme/night_guild_background.dart' show CultivationBackground;

// ── Path definitions ────────────────────────────────────

const _availablePaths = [
  ('Shadow Arts', 'Cybersecurity — Infiltration, Recon, Defense'),
  ('Realm Architect', 'Game Dev — World Creation, Logic, Math'),
  ('Formation Master', 'Web Dev — Arrays, Frameworks, Scaling'),
  ('Artifact Refiner', 'Mobile Dev — UI/UX, Cross-Platform, Tool Crafting'),
  ('Body Cultivator', 'Fitness — Strength, Endurance, Discipline'),
  ('Scripture Keeper', 'Studying — Focus, Retention, Analysis'),
  ('Inscription Master', 'Creative — Art, Music, Design'),
];

/// Canonical path → icon map. Imported by other screens to stay in sync.
IconData pathIconFor(String path) {
  switch (path) {
    case 'Shadow Arts':
      return Icons.security;
    case 'Realm Architect':
      return Icons.castle;
    case 'Formation Master':
      return Icons.web;
    case 'Artifact Refiner':
      return Icons.phone_android;
    case 'Body Cultivator':
      return Icons.fitness_center;
    case 'Scripture Keeper':
      return Icons.menu_book;
    case 'Inscription Master':
      return Icons.brush;
    default:
      return Icons.auto_awesome;
  }
}

// ── OnboardingScreen ────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  int _step = 0; // 0 = name, 1 = path picker, 2 = confirm
  String _playerName = '';
  String _selectedPath = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _confirmName() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _playerName = name;
      _step = 1;
    });
  }

  void _selectPath(String path) {
    setState(() => _selectedPath = path);
  }

  void _confirmPath() {
    if (_selectedPath.isEmpty) return;
    setState(() => _step = 2);
  }

  Future<void> _onEnter() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    gameService.errorNotifier.value = null;

    final player = PlayerData(
      name: _playerName,
      mainPath: _selectedPath,
    );

    debugPrint('[Onboarding] SAVING profile → name: ${player.name} | mainPath: ${player.mainPath}');

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) {
          setState(() => _step -= 1);
        }
      },
      child: Scaffold(
        body: CultivationBackground(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _step == 0
                  ? _buildNameStep(cs)
                  : _step == 1
                      ? _buildPathStep(cs)
                      : _buildEnterStep(cs),
            ),
          ),
        ),
      ),
    );
  }

  // ── Screen 1: Name ────────────────────────────────────

  Widget _buildNameStep(ColorScheme cs) {
    return Padding(
      key: const ValueKey('name'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What is your name, cultivator?',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 20,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _confirmName(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirmName,
              child: const Text('CONFIRM'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen 2: Path Picker ─────────────────────────────

  Widget _buildPathStep(ColorScheme cs) {
    return Padding(
      key: const ValueKey('path'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'The System reads your potential.\nChoose your path.',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _availablePaths.length,
              itemBuilder: (context, index) {
                final (name, domain) = _availablePaths[index];
                final selected = _selectedPath == name;
                return GestureDetector(
                  onTap: () => _selectPath(name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? cs.primary : cs.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pathIconFor(name),
                          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          domain,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedPath.isEmpty ? null : _confirmPath,
              child: const Text('CONFIRM'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Screen 3: Enter ───────────────────────────────────

  Widget _buildEnterStep(ColorScheme cs) {
    return Padding(
      key: const ValueKey('enter'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pathIconFor(_selectedPath),
            color: cs.primary,
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            _playerName,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedPath,
            style: TextStyle(
              color: cs.primary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Synchronization complete.\nCultivation begins.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _onEnter,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ENTER THE SYSTEM'),
            ),
          ),
        ],
      ),
    );
  }
}
