import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/guild_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/check_in_overlay.dart';
import 'widgets/level_up_overlay.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Index 2 = Home (character screen) — default on launch
  int _selectedIndex = 2;

  final List<Widget> _screens = const [
    StatsScreen(),
    QuestsScreen(),
    HomeScreen(),
    GuildScreen(),
    ProfileScreen(),
  ];

  late int _currentLevel;

  @override
  void initState() {
    super.initState();
    _currentLevel = playerNotifier.value.level;
    playerNotifier.addListener(_onPlayerChange);
  }

  void _onPlayerChange() {
    final newLevel = playerNotifier.value.level;
    if (newLevel > _currentLevel) {
      final isInitialLoad = gameService.isLoadingNotifier.value;
      _currentLevel = newLevel;

      if (!isInitialLoad && mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (ctx, a1, a2) => LevelUpOverlay(
            newLevel: newLevel,
            onComplete: () => Navigator.of(ctx).pop(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    playerNotifier.removeListener(_onPlayerChange);
    super.dispose();
  }

  void _onNavTap(int index) async {
    // Tapping the center Home icon when NOT checked in triggers the ceremony
    if (index == 2 && !checkedInNotifier.value) {
      setState(() => _selectedIndex = index);
      
      await gameService.checkIn();
      if (!mounted) return;
      
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        pageBuilder: (ctx, a1, a2) => CheckInOverlay(
          onComplete: () => Navigator.of(ctx).pop(),
        ),
      );
      return;
    }
    
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: checkedInNotifier,
        builder: (_, checkedIn, _) => _buildBottomNav(cs, bg, checkedIn),
      ),
    );
  }

  Widget _buildBottomNav(ColorScheme cs, Color bg, bool checkedIn) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.25),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          // Stats — cultivation base / dantian state
          const BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            activeIcon: Icon(Icons.self_improvement, size: 28),
            label: 'Cultivation',
          ),
          // Trials — path challenges
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_edu),
            activeIcon: Icon(Icons.history_edu, size: 28),
            label: 'Trials',
          ),
          // Home — center FAB (meditation ritual button)
          BottomNavigationBarItem(
            icon: _buildCenterFab(cs, checkedIn),
            label: '',
          ),
          // Sect — the cultivators' gathering
          const BottomNavigationBarItem(
            icon: Icon(Icons.temple_hindu),
            activeIcon: Icon(Icons.temple_hindu, size: 28),
            label: 'Sect',
          ),
          // Identity — dao name and spirit root
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_4),
            activeIcon: Icon(Icons.person_4, size: 28),
            label: 'Identity',
          ),
        ],
      ),
    );
  }

  Widget _buildCenterFab(ColorScheme cs, bool checkedIn) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: checkedIn
            ? cs.primary.withValues(alpha: 0.55)
            : cs.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: checkedIn ? 0.2 : 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        // Checked-in → sect base; not yet → lightning rune for meditation ritual
        checkedIn ? Icons.fort : Icons.bolt,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
