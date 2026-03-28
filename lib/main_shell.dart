import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/guild_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/check_in_overlay.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/mystic_nav_bar.dart';

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
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      extendBody: true, // Allows nav to blend with background
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: checkedInNotifier,
        builder: (_, checkedIn, _) => MysticSectNav(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          checkedIn: checkedIn,
        ),
      ),
    );
  }
}
