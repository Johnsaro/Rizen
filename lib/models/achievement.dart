import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final int repReward;
  final String? titleReward;
  final bool comingSoon;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    this.repReward = 0,
    this.titleReward,
    this.comingSoon = false,
  });
}

class AchievementCatalog {
  AchievementCatalog._();

  static const _consistency = 'Consistency';
  static const _combat = 'Combat';
  static const _quest = 'Quests';
  static const _knowledge = 'Knowledge';

  static const all = <Achievement>[
    // ── Consistency ──────────────────────────────────────
    Achievement(
      id: 'first_step',
      name: 'First Step',
      description: 'Check in for the first time',
      category: _consistency,
      icon: Icons.flag_outlined,
    ),
    Achievement(
      id: 'the_consistent',
      name: 'The Consistent',
      description: 'Reach a 7-day streak',
      category: _consistency,
      icon: Icons.local_fire_department,
      repReward: 200,
      titleReward: 'The Consistent',
    ),
    Achievement(
      id: 'unwavering',
      name: 'Unwavering',
      description: 'Reach a 30-day streak',
      category: _consistency,
      icon: Icons.local_fire_department,
      repReward: 500,
      titleReward: 'Unwavering',
    ),
    Achievement(
      id: 'the_relentless',
      name: 'The Relentless',
      description: 'Reach a 100-day streak',
      category: _consistency,
      icon: Icons.local_fire_department,
      repReward: 2000,
      titleReward: 'The Relentless',
    ),
    Achievement(
      id: 'ascendant',
      name: 'Ascendant',
      description: 'Reach a 365-day streak',
      category: _consistency,
      icon: Icons.auto_awesome,
      titleReward: 'Ascendant',
    ),

    // ── Combat ───────────────────────────────────────────
    Achievement(
      id: 'first_blood',
      name: 'First Blood',
      description: 'Win your first battle',
      category: _combat,
      icon: Icons.whatshot,
    ),
    Achievement(
      id: 'monster_slayer',
      name: 'Monster Slayer',
      description: 'Defeat 10 monsters',
      category: _combat,
      icon: Icons.whatshot,
      repReward: 300,
    ),
    Achievement(
      id: 'boss_killer',
      name: 'Boss Killer',
      description: 'Defeat your first boss',
      category: _combat,
      icon: Icons.shield,
      titleReward: 'The Hunter',
      comingSoon: true,
    ),
    Achievement(
      id: 'raid_cleared',
      name: 'Raid Cleared',
      description: 'Defeat a Raid Boss',
      category: _combat,
      icon: Icons.military_tech,
      titleReward: 'Raid Breaker',
      comingSoon: true,
    ),
    Achievement(
      id: 'perfect_fight',
      name: 'Perfect Fight',
      description: 'Win a battle without taking damage',
      category: _combat,
      icon: Icons.stars,
      repReward: 500,
      comingSoon: true,
    ),

    // ── Quests ───────────────────────────────────────────
    Achievement(
      id: 'quest_taker',
      name: 'Quest Taker',
      description: 'Complete your first quest',
      category: _quest,
      icon: Icons.check_circle_outline,
    ),
    Achievement(
      id: 'grinder',
      name: 'Grinder',
      description: 'Complete 50 quests',
      category: _quest,
      icon: Icons.repeat,
      repReward: 300,
    ),
    Achievement(
      id: 'sss_cleared',
      name: 'SSS Cleared',
      description: 'Complete an SSS rank quest',
      category: _quest,
      icon: Icons.workspace_premium,
      titleReward: 'Shadow Analyst',
      comingSoon: true,
    ),

    // ── Knowledge ────────────────────────────────────────
    Achievement(
      id: 'scholar',
      name: 'Scholar',
      description: 'Purchase your first knowledge item',
      category: _knowledge,
      icon: Icons.menu_book,
    ),
    Achievement(
      id: 'librarian',
      name: 'Librarian',
      description: 'Own 3 knowledge items',
      category: _knowledge,
      icon: Icons.local_library,
      repReward: 200,
    ),
    Achievement(
      id: 'living_encyclopedia',
      name: 'Living Encyclopedia',
      description: 'Own all 6 knowledge items',
      category: _knowledge,
      icon: Icons.auto_stories,
      titleReward: 'The Sage',
    ),

    // ── Level milestones ─────────────────────────────────
    Achievement(
      id: 'level_10',
      name: 'Rising Star',
      description: 'Reach Level 10',
      category: _consistency,
      icon: Icons.arrow_upward,
      repReward: 100,
    ),
    Achievement(
      id: 'level_25',
      name: 'Veteran',
      description: 'Reach Level 25',
      category: _consistency,
      icon: Icons.arrow_upward,
      repReward: 500,
      titleReward: 'Veteran',
    ),
  ];

  static final byId = {for (final a in all) a.id: a};

  static Achievement? get(String id) => byId[id];
}
