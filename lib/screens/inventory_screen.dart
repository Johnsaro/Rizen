import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/player_data.dart';
import '../theme/rank_colors.dart';
import '../theme/night_guild_background.dart';
import 'flashcard/flashcard_screen.dart';

// Catalog of all obtainable artifacts — icon, path, rank, combat perk.
const _weaponCatalog = <String, ({IconData icon, String itemClass, String rank, String perk})>{
  'Recon Blade':    (icon: Icons.bolt,               itemClass: 'Shadow Arts', rank: 'B', perk: 'Enlightenment: Shadow Arts questions · Artifact hint'),
  'Debug Shield':   (icon: Icons.auto_awesome,         itemClass: 'Formation Master',   rank: 'C', perk: 'Enlightenment: Formation Master questions · Artifact hint'),
  'Enum Staff':     (icon: Icons.manage_search,           itemClass: 'Shadow Arts', rank: 'A', perk: 'Enlightenment: Shadow Arts questions · Artifact hint'),
  'Stealth Cloak':  (icon: Icons.visibility_off, itemClass: 'Shadow Arts', rank: 'S', perk: 'Enlightenment: Shadow Arts questions · Artifact hint'),
  'Code Forge':     (icon: Icons.construction,               itemClass: 'Formation Master',   rank: 'B', perk: 'Enlightenment: Formation Master questions · Artifact hint'),
  'Exploit Dagger': (icon: Icons.bolt,                    itemClass: 'Shadow Arts', rank: 'A', perk: 'Enlightenment: Shadow Arts questions · Artifact hint'),
};

/// Case-insensitive artifact catalog lookup.
({IconData icon, String itemClass, String rank, String perk})? _lookupWeapon(String name) {
  final exact = _weaponCatalog[name];
  if (exact != null) return exact;
  final lower = name.toLowerCase();
  for (final entry in _weaponCatalog.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return null;
}

const _cosmeticCatalog = <String, ({IconData icon, String category, String description})>{
  'Shadow Environment':   (icon: Icons.nightlight_round,      category: 'Theme',  description: 'Abyssal Void UI variant'),
  'Synthwave Atmosphere': (icon: Icons.waves,                 category: 'Theme',  description: 'Celestial Realm mystical purple gradients'),
  'Guild Title Frame':    (icon: Icons.border_outer,          category: 'Frame',  description: 'Ornate gold frame around your identity card'),
  'Cyber Frame':          (icon: Icons.memory,                category: 'Frame',  description: 'Glowing Qi circuitry border'),
  'XP Flame Trail':       (icon: Icons.local_fire_department, category: 'Effect', description: 'Animated Qi flame effect on progress bar'),
  'Neon Arsenal':         (icon: Icons.style,                 category: 'Effect', description: 'Heavy glowing aura on equipped artifacts'),
};

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedTab = 0;
  bool _equipping = false;

  @override
  void initState() {
    super.initState();
    final player = playerNotifier.value;
    final owned = _ownedWeapons(player);
    // If player has artifacts but nothing attuned, land on Stored tab
    if (player.equippedWeapon.isEmpty && owned.isNotEmpty) {
      _selectedTab = 1;
    }
  }


  Future<void> _handleEquip(String weaponName) async {
    if (_equipping) return;
    setState(() => _equipping = true);
    gameService.errorNotifier.value = null;
    try {
      await gameService.equipWeapon(weaponName);
      if (mounted && gameService.errorNotifier.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gameService.errorNotifier.value!)),
        );
      } else if (mounted) {
        // Switch to Attuned tab on success
        setState(() => _selectedTab = 0);
      }
    } finally {
      if (mounted) setState(() => _equipping = false);
    }
  }

  Future<void> _handleUnequip() async {
    if (_equipping) return;
    setState(() => _equipping = true);
    gameService.errorNotifier.value = null;
    try {
      await gameService.equipWeapon('');
      if (mounted && gameService.errorNotifier.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gameService.errorNotifier.value!)),
        );
      } else if (mounted) {
        // Switch to Stored tab on success
        setState(() => _selectedTab = 1);
      }
    } finally {
      if (mounted) setState(() => _equipping = false);
    }
  }

  Future<void> _handleEquipCosmetic(String category, String name) async {
    if (_equipping) return;
    setState(() => _equipping = true);
    gameService.errorNotifier.value = null;
    try {
      await gameService.equipCosmetic(category, name);
      if (mounted && gameService.errorNotifier.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gameService.errorNotifier.value!)),
        );
      }
    } finally {
      if (mounted) setState(() => _equipping = false);
    }
  }

  void _openStudy(String weaponTag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          weaponTag: weaponTag,
          mode: FlashcardMode.study,
        ),
      ),
    );
  }

  void _openRepair(String weaponTag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          weaponTag: weaponTag,
          mode: FlashcardMode.repair,
          requiredCorrect: 3,
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    final tabs = ['Attuned', 'Stored', 'Degraded', 'Treasures'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _selectedTab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outline),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected ? Colors.black : cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDurabilityBar(double value, ColorScheme cs) {
    final Color barColor = value > 0.5
        ? cs.primary
        : value > 0.25
            ? Colors.orange
            : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Refinement',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.6))),
            Text('${(value * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: cs.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(String rank) {
    final color = rankColor(rank);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(rank,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildItemCard({
    required ColorScheme cs,
    required IconData icon,
    required String name,
    required String itemClass,
    required String rank,
    required double durability,
    required List<Widget> buttons,
    String? perk,
    Widget? warning,
  }) {
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.cinzel(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(_displayPathName(itemClass),
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55))),
                    if (perk != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        perk,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildRankBadge(rank),
            ],
          ),
          const SizedBox(height: 12),
          _buildDurabilityBar(durability, cs),
          if (warning != null) ...[const SizedBox(height: 8), warning],
          const SizedBox(height: 12),
          Row(children: buttons),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required ColorScheme cs,
    required String label,
    required VoidCallback? onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : (onTap != null ? cs.primary : cs.primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: outlined ? cs.outline : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: outlined ? cs.onSurface : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.cinzel(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Text(
          message,
          style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  double _getDurability(PlayerData player, String weaponName) {
    final raw = player.weaponDurability[weaponName] ?? 100;
    return (raw / 100.0).clamp(0.0, 1.0);
  }

  Widget _buildEquippedTab(PlayerData player, ColorScheme cs) {
    final meta = _lookupWeapon(player.equippedWeapon);
    if (player.equippedWeapon.isEmpty || meta == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ATTUNED', cs),
          _buildEmptyState('No artifact attuned.\nSelect one from your collection.', cs),
        ],
      );
    }
    final dur = _getDurability(player, player.equippedWeapon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ATTUNED  1 / ${_ownedWeapons(player).length}', cs),
        _buildItemCard(
          cs: cs,
          icon: meta.icon,
          name: player.equippedWeapon,
          itemClass: meta.itemClass,
          rank: meta.rank,
          durability: dur,
          perk: meta.perk,
          warning: dur < 0.7 ? Text(
            dur == 0 ? 'DEGRADED — Refine to restore' : 'Refinement low — consider Refine mode',
            style: TextStyle(color: dur == 0 ? Colors.red : Colors.orange, fontSize: 11),
          ) : null,
          buttons: [
            _buildActionButton(
              cs: cs,
              label: _equipping ? '...' : 'RELEASE',
              outlined: true,
              onTap: _equipping ? null : _handleUnequip,
            ),
            const SizedBox(width: 8),
            if (dur < 0.7) ...[
              _buildActionButton(
                cs: cs,
                label: 'REFINE',
                onTap: () => _openRepair(player.equippedWeapon),
              ),
              const SizedBox(width: 8),
            ],
            _buildActionButton(
              cs: cs,
              label: 'MEDITATE',
              onTap: () => _openStudy(player.equippedWeapon),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenchedTab(PlayerData player, ColorScheme cs) {
    final benched = _ownedWeapons(player)
        .where((name) => name != player.equippedWeapon)
        .toList();

    if (benched.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('COLLECTION', cs),
          _buildEmptyState('No stored artifacts.\nObtain them from the Pavilion.', cs),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COLLECTION', cs),
        ...benched.map((name) {
          final meta = _lookupWeapon(name);
          if (meta == null) return const SizedBox.shrink();
          final dur = _getDurability(player, name);
          return _buildItemCard(
            cs: cs,
            icon: meta.icon,
            name: name,
            itemClass: meta.itemClass,
            rank: meta.rank,
            durability: dur,
            perk: meta.perk,
            buttons: [
              _buildActionButton(
                cs: cs,
                label: _equipping ? '...' : 'ATTUNE',
                onTap: _equipping ? null : () => _handleEquip(name),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                cs: cs,
                label: 'REFINE',
                outlined: true,
                onTap: () => _openRepair(name),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                cs: cs,
                label: 'MEDITATE',
                onTap: () => _openStudy(name),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDegradedTab(PlayerData player, ColorScheme cs) {
    final degraded = _ownedWeapons(player)
        .where((name) => (player.weaponDurability[name] ?? 100) == 0)
        .toList();

    if (degraded.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('DEGRADED', cs),
          _buildEmptyState('No degraded artifacts.\nKeep training to maintain your arsenal.', cs),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DEGRADED  ${degraded.length}', cs),
        ...degraded.map((name) {
          final meta = _lookupWeapon(name);
          if (meta == null) return const SizedBox.shrink();
          return _buildItemCard(
            cs: cs,
            icon: meta.icon,
            name: name,
            itemClass: meta.itemClass,
            rank: meta.rank,
            durability: 0.0,
            warning: Text(
              'DEGRADED — Complete Refine mode to restore',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
            buttons: [
              _buildActionButton(
                cs: cs,
                label: 'REFINE',
                onTap: () => _openRepair(name),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Returns all weapon names from inventory that exist in the catalog.
  List<String> _ownedWeapons(PlayerData player) => player.inventory.keys
      .where((name) => _lookupWeapon(name) != null)
      .toList();

  /// Returns all cosmetic names from inventory that exist in the catalog.
  List<String> _ownedCosmetics(PlayerData player) => player.inventory.keys
      .where((name) => _cosmeticCatalog.containsKey(name))
      .toList();

  Widget _buildCosmeticsTab(PlayerData player, ColorScheme cs) {
    final owned = _ownedCosmetics(player);
    if (owned.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('TREASURES', cs),
          _buildEmptyState('No treasures owned.\nObtain them from the Pavilion.', cs),
        ],
      );
    }

    // Group by category
    final grouped = <String, List<String>>{};
    for (final name in owned) {
      final cat = _cosmeticCatalog[name]!.category;
      grouped.putIfAbsent(cat, () => []).add(name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TREASURES', cs),
        ...grouped.entries.map((entry) {
          final cat = entry.key;
          final items = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(
                  cat.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              ...items.map((name) {
                final meta = _cosmeticCatalog[name]!;
                final isEquipped = player.equippedCosmetics[cat] == name;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEquipped ? cs.secondary : cs.outline,
                      width: isEquipped ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(meta.icon, color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: GoogleFonts.cinzel(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: cs.onSurface)),
                            const SizedBox(height: 4),
                            Text(
                              meta.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        cs: cs,
                        label: isEquipped ? 'RELEASE' : 'ATTUNE',
                        outlined: isEquipped,
                        onTap: _equipping
                            ? null
                            : () => _handleEquipCosmetic(cat, isEquipped ? '' : name),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_equipping,
      child: ValueListenableBuilder<PlayerData>(
      valueListenable: playerNotifier,
      builder: (_, player, _) {
        final cs = Theme.of(context).colorScheme;

        Widget tabContent;
        switch (_selectedTab) {
          case 0:
            tabContent = _buildEquippedTab(player, cs);
            break;
          case 1:
            tabContent = _buildBenchedTab(player, cs);
            break;
          case 2:
            tabContent = _buildDegradedTab(player, cs);
            break;
          case 3:
            tabContent = _buildCosmeticsTab(player, cs);
            break;
          default:
            tabContent = _buildEquippedTab(player, cs);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CultivationBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                          color: cs.onSurface,
                        ),
                        Expanded(
                          child: Text(
                            'Arsenal',
                            style: GoogleFonts.cinzel(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        // Spirit Stones balance badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTabBar(cs),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: tabContent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    );
  }

  String _displayPathName(String className) => className;
}
