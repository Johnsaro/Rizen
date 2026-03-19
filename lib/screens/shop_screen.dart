import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../theme/night_guild_background.dart';
import '../theme/rank_colors.dart';

// ── Data models ───────────────────────────────────────────

class _ArsenalItem {
  final String name;
  final IconData icon;
  final String className;
  final String skill;
  final String statBonus;
  final String rank;
  final int cost;
  const _ArsenalItem({
    required this.name,
    required this.icon,
    required this.className,
    required this.skill,
    required this.statBonus,
    required this.rank,
    required this.cost,
  });
}

class _ConsumableItem {
  final String name;
  final IconData icon;
  final String effect;
  final String duration;
  final int cost;
  const _ConsumableItem({
    required this.name,
    required this.icon,
    required this.effect,
    required this.duration,
    required this.cost,
  });
}

class _KnowledgeItem {
  final String name;
  final String className;
  final String description;
  final String rank;
  final int cost;
  const _KnowledgeItem({
    required this.name,
    required this.className,
    required this.description,
    required this.rank,
    required this.cost,
  });
}

class _CosmeticItem {
  final String name;
  final IconData icon;
  final String description;
  final String category;
  final int cost;
  const _CosmeticItem({
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.cost,
  });
}

// ── Catalog data ──────────────────────────────────────────

const _arsenal = [
  _ArsenalItem(
    name: 'Recon Blade',
    icon: Icons.bolt,
    className: 'Shadow Arts',
    skill: 'nmap -sV -sC -oN scan.txt [IP]',
    statBonus: '+5 Recon',
    rank: 'B',
    cost: 300,
  ),
  _ArsenalItem(
    name: 'Debug Shield',
    icon: Icons.auto_awesome,
    className: 'Formation Master',
    skill: 'Check your loop exit condition first',
    statBonus: '+4 Problem Solving',
    rank: 'C',
    cost: 150,
  ),
  _ArsenalItem(
    name: 'Enum Staff',
    icon: Icons.manage_search,
    className: 'Shadow Arts',
    skill: 'gobuster dir -u [URL] -w [wordlist]',
    statBonus: '+3 Enumeration',
    rank: 'A',
    cost: 500,
  ),
  _ArsenalItem(
    name: 'Stealth Cloak',
    icon: Icons.visibility_off,
    className: 'Shadow Arts',
    skill: 'Always clear logs after access',
    statBonus: '+4 Stealth',
    rank: 'S',
    cost: 800,
  ),
  _ArsenalItem(
    name: 'Code Forge',
    icon: Icons.construction,
    className: 'Formation Master',
    skill: 'Write tests before fixing bugs',
    statBonus: '+5 Build Speed',
    rank: 'B',
    cost: 350,
  ),
  _ArsenalItem(
    name: 'Exploit Dagger',
    icon: Icons.bolt,
    className: 'Shadow Arts',
    skill: 'searchsploit [service] [version]',
    statBonus: '+5 Exploitation',
    rank: 'A',
    cost: 550,
  ),
];

const _consumables = [
  _ConsumableItem(
    name: 'Focus Boost',
    icon: Icons.psychology,
    effect: '+50% Qi from all trials',
    duration: '2 hours',
    cost: 100,
  ),
  _ConsumableItem(
    name: 'Double Rep',
    icon: Icons.stars,
    effect: '+100% Spirit Stones earned',
    duration: '1 hour',
    cost: 150,
  ),
  _ConsumableItem(
    name: 'Durability Kit',
    icon: Icons.build_outlined,
    effect: 'Restores one artifact to full refinement',
    duration: 'Instant',
    cost: 200,
  ),
  _ConsumableItem(
    name: 'Health Potion',
    icon: Icons.favorite_outline,
    effect: 'Restores 300 Vitality instantly',
    duration: 'Instant',
    cost: 100,
  ),
  _ConsumableItem(
    name: 'Shield Charge',
    icon: Icons.auto_awesome,
    effect: 'Adds 1 Protective Talisman (Dao Heart shield)',
    duration: 'Instant',
    cost: 250,
  ),
  _ConsumableItem(
    name: 'Time Warp',
    icon: Icons.hourglass_bottom,
    effect: 'Freezes a daily trial deadline by 24 hours',
    duration: 'Instant',
    cost: 175,
  ),
  _ConsumableItem(
    name: 'XP Surge',
    icon: Icons.arrow_upward,
    effect: 'Next trial gives double Qi',
    duration: '1 trial',
    cost: 125,
  ),
];

const _knowledge = [
  _KnowledgeItem(
    name: 'OWASP Top 10 Grimoire',
    className: 'Shadow Arts',
    description: '10 critical web vulnerabilities explained with examples',
    rank: 'B',
    cost: 400,
  ),
  _KnowledgeItem(
    name: 'Nmap Codex',
    className: 'Shadow Arts',
    description: 'Complete nmap flags and usage reference',
    rank: 'C',
    cost: 200,
  ),
  _KnowledgeItem(
    name: 'Clean Code Scroll',
    className: 'Formation Master',
    description: 'Best practices every cultivator should know',
    rank: 'D',
    cost: 100,
  ),
  _KnowledgeItem(
    name: 'Linux PrivEsc Handbook',
    className: 'Shadow Arts',
    description: 'Real privilege escalation techniques and methods',
    rank: 'A',
    cost: 600,
  ),
  _KnowledgeItem(
    name: 'Git Mastery Tome',
    className: 'Formation Master',
    description: 'Branching strategies, rebasing, and conflict resolution',
    rank: 'C',
    cost: 180,
  ),
  _KnowledgeItem(
    name: 'SQL Injection Grimoire',
    className: 'Shadow Arts',
    description: 'Injection payloads, bypass techniques, and defenses',
    rank: 'B',
    cost: 350,
  ),
];

const _cosmetics = [
  _CosmeticItem(
    name: 'Shadow Environment',
    icon: Icons.nightlight_round,
    description: 'Abyssal Void UI variant',
    category: 'Theme',
    cost: 500,
  ),
  _CosmeticItem(
    name: 'Synthwave Atmosphere',
    icon: Icons.waves,
    description: 'Celestial Realm mystical purple gradients',
    category: 'Theme',
    cost: 600,
  ),
  _CosmeticItem(
    name: 'Guild Title Frame',
    icon: Icons.border_outer,
    description: 'Ornate gold frame around your identity card',
    category: 'Frame',
    cost: 300,
  ),
  _CosmeticItem(
    name: 'Cyber Frame',
    icon: Icons.memory,
    description: 'Glowing Qi circuitry border',
    category: 'Frame',
    cost: 450,
  ),
  _CosmeticItem(
    name: 'XP Flame Trail',
    icon: Icons.local_fire_department,
    description: 'Animated Qi flame effect on progress bar',
    category: 'Effect',
    cost: 400,
  ),
  _CosmeticItem(
    name: 'Neon Arsenal',
    icon: Icons.style,
    description: 'Heavy glowing aura on equipped artifacts',
    category: 'Effect',
    cost: 350,
  ),
];

// ── Screen ────────────────────────────────────────────────

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Artifacts', 'Pills', 'Knowledge', 'Treasures'];
  final Set<String> _purchasingItems = {};
  final Set<String> _usingItems = {};

  static const _deferredConsumables = {'Durability Kit', 'Time Warp'};

  Future<void> _handlePurchase(String itemName, int cost) async {
    if (_purchasingItems.contains(itemName)) return;
    final player = playerNotifier.value;
    // Guard: do not allow purchasing already-owned items
    if (player.inventory.containsKey(itemName)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName is already in your arsenal!')),
        );
      }
      return;
    }
    if (player.spiritStones < cost) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Not enough Spirit Stones (need $cost)')));
      }
      return;
    }
    setState(() => _purchasingItems.add(itemName));
    try {
      await gameService.purchaseItem(itemName, cost);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$itemName obtained!')));
      }
    } finally {
      if (mounted) setState(() => _purchasingItems.remove(itemName));
    }
  }

  Future<void> _handleUseItem(String itemName) async {
    if (_usingItems.contains(itemName)) return;
    setState(() => _usingItems.add(itemName));
    try {
      final error = await gameService.useItem(itemName);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? '$itemName consumed!')),
        );
      }
    } finally {
      if (mounted) setState(() => _usingItems.remove(itemName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(cs),
              _buildTabs(cs),
              Expanded(child: _buildContent(context, cs)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios,
              color: cs.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'PILL PAVILION',
              style: GoogleFonts.cinzel(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          // Spirit Stones balance
          ValueListenableBuilder<PlayerData>(
            valueListenable: playerNotifier,
            builder: (_, player, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars, color: cs.secondary, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${player.spiritStones} Stones',
                    style: GoogleFonts.jetBrainsMono(
                      color: cs.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ColorScheme cs) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final selected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? cs.primary : cs.outline),
              ),
              child: Center(
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    switch (_selectedTab) {
      case 0:
        return _buildArsenal(context, cs);
      case 1:
        return _buildConsumables(context, cs);
      case 2:
        return _buildKnowledge(context, cs);
      case 3:
        return _buildCosmetics(context, cs);
      default:
        return const SizedBox();
    }
  }

  // ── Arsenal tab ──────────────────────────────────────────

  Widget _buildArsenal(BuildContext context, ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _arsenal.length,
      itemBuilder: (_, i) {
        final item = _arsenal[i];
        return _arsenalCard(context, cs, item);
      },
    );
  }

  Widget _arsenalCard(BuildContext context, ColorScheme cs, _ArsenalItem item) {
    final rc = rankColor(item.rank);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: cs.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayPathName(item.className),
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Rank badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: rc.withValues(alpha: 0.4)),
                ),
                child: Text(
                  item.rank,
                  style: GoogleFonts.jetBrainsMono(
                    color: rc,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Skill hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: cs.onSurface.withValues(alpha: 0.3),
                  size: 13,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.skill,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                item.statBonus,
                style: TextStyle(
                  color: cs.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${item.cost} Stones',
                style: GoogleFonts.jetBrainsMono(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              _buyButton(context, cs, item.name, item.cost),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pills tab ──────────────────────────────────────

  Widget _buildConsumables(BuildContext context, ColorScheme cs) {
    return ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      builder: (_, player, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _consumables.length,
          itemBuilder: (_, i) {
            final item = _consumables[i];
            final owned = player.inventory[item.name] ?? 0;
            final isDeferred = _deferredConsumables.contains(item.name);
            final isActive = player.isPillActive(item.name);

            // Item Name mapping
            String displayName = item.name;
            if (item.name == 'Focus Boost') displayName = 'Focus Elixir';
            if (item.name == 'Double Rep') displayName = 'Spirit Tonic';
            if (item.name == 'XP Surge') displayName = 'Qi Surge Pill';
            if (item.name == 'Health Potion') displayName = 'Healing Pill';
            if (item.name == 'Shield Charge') displayName = 'Protective Talisman';
            if (item.name == 'Durability Kit') displayName = 'Refinement Kit';
            if (item.name == 'Time Warp') displayName = 'Fate Reversal Talisman';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? cs.tertiary.withValues(alpha: 0.5)
                      : cs.outline,
                ),
              ),
              child: Row(
                children: [
                  // Icon with quantity badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: cs.secondary, size: 20),
                      ),
                      if (owned > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '×$owned',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.effect,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.duration,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.cost}',
                        style: GoogleFonts.jetBrainsMono(
                          color: cs.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stones',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Hide BUY when buff is active — no point buying more mid-buff
                      if (!isActive)
                        _consumableBuyButton(cs, item.name, item.cost, player),
                      // ACTIVE badge — shown even when inventory is 0
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: cs.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: cs.tertiary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: cs.tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ] else if (owned > 0) ...[
                        const SizedBox(height: 4),
                        if (isDeferred)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: cs.outline.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SOON',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => _handleUseItem(item.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'USE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _consumableBuyButton(
    ColorScheme cs,
    String itemName,
    int cost,
    PlayerData player,
  ) {
    final canAfford = player.spiritStones >= cost;
    return GestureDetector(
      onTap: canAfford ? () => _handlePurchase(itemName, cost) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: canAfford ? cs.primary : cs.outline.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'BUY',
          style: TextStyle(
            color: canAfford
                ? Colors.white
                : cs.onSurface.withValues(alpha: 0.3),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ── Knowledge tab ─────────────────────────────────────────

  Widget _buildKnowledge(BuildContext context, ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _knowledge.length,
      itemBuilder: (_, i) {
        final item = _knowledge[i];
        final rc = rankColor(item.rank);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book, color: cs.secondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayPathName(item.className),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: rc.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      item.rank,
                      style: GoogleFonts.jetBrainsMono(
                        color: rc,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"${item.description}"',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${item.cost} Stones',
                    style: GoogleFonts.jetBrainsMono(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buyButton(context, cs, item.name, item.cost),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Treasures tab ─────────────────────────────────────────

  Widget _buildCosmetics(BuildContext context, ColorScheme cs) {
    return ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      builder: (_, player, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _cosmetics.length,
          itemBuilder: (_, i) {
            final item = _cosmetics[i];
            final isOwned = player.inventory.containsKey(item.name);
            final isEquipped = player.equippedCosmetics[item.category] == item.name;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isOwned ? cs.primary.withValues(alpha: 0.05) : cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEquipped
                      ? cs.primary.withValues(alpha: 0.5)
                      : cs.outline,
                  width: isEquipped ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: cs.secondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isEquipped) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'EQUIPPED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.cost}',
                        style: GoogleFonts.jetBrainsMono(
                          color: cs.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stones',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buyButton(context, cs, item.name, item.cost),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Shared buy button ─────────────────────────────────────

  Widget _buyButton(
    BuildContext context,
    ColorScheme cs,
    String itemName,
    int cost,
  ) {
    return ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      builder: (_, player, _) {
        final owned = player.inventory.containsKey(itemName);
        final canAfford = player.spiritStones >= cost;

        if (owned) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'OWNED',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _handlePurchase(itemName, cost),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: canAfford ? cs.primary : cs.outline.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'BUY',
              style: TextStyle(
                color: canAfford
                    ? Colors.white
                    : cs.onSurface.withValues(alpha: 0.3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayPathName(String className) => className;
}
