/// A weapon from the catalog (read-only, seeded in Supabase).
class Weapon {
  final String id;
  final String name;
  final String rank;
  final String sect;
  final String pathTag;
  final List<String> topicTags;
  final String description;
  final int cost;
  final int durabilityMax;
  final String iconName;

  const Weapon({
    required this.id,
    required this.name,
    required this.rank,
    required this.sect,
    required this.pathTag,
    required this.topicTags,
    required this.description,
    required this.cost,
    required this.durabilityMax,
    required this.iconName,
  });

  /// Whether this weapon is free (starter weapon for the path).
  bool get isFree => cost == 0;

  factory Weapon.fromRow(Map<String, dynamic> row) {
    final rawTags = row['topic_tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        tags.add(t as String);
      }
    }

    return Weapon(
      id: row['id'] as String,
      name: row['name'] as String,
      rank: (row['rank'] as String?) ?? 'F',
      sect: (row['sect'] as String?) ?? '',
      pathTag: (row['path_tag'] as String?) ?? '',
      topicTags: tags,
      description: (row['description'] as String?) ?? '',
      cost: (row['cost'] as num?)?.toInt() ?? 0,
      durabilityMax: (row['durability_max'] as num?)?.toInt() ?? 100,
      iconName: (row['icon_name'] as String?) ?? 'bolt',
    );
  }
}

/// A player's owned instance of a weapon (with durability tracking).
class PlayerWeapon {
  final String id;
  final String userId;
  final String weaponId;
  final int durability;
  final bool isEquipped;
  final DateTime acquiredAt;

  /// Populated after joining with weapons table.
  final Weapon? weapon;

  const PlayerWeapon({
    required this.id,
    required this.userId,
    required this.weaponId,
    required this.durability,
    this.isEquipped = false,
    required this.acquiredAt,
    this.weapon,
  });

  double get durabilityPercent =>
      weapon != null ? durability / weapon!.durabilityMax : durability / 100;

  bool get isBroken => durability <= 0;

  PlayerWeapon copyWith({
    int? durability,
    bool? isEquipped,
  }) {
    return PlayerWeapon(
      id: id,
      userId: userId,
      weaponId: weaponId,
      durability: durability ?? this.durability,
      isEquipped: isEquipped ?? this.isEquipped,
      acquiredAt: acquiredAt,
      weapon: weapon,
    );
  }

  factory PlayerWeapon.fromRow(Map<String, dynamic> row) {
    // If joined with weapons table, parse the nested weapon
    Weapon? weapon;
    if (row['weapons'] is Map<String, dynamic>) {
      weapon = Weapon.fromRow(row['weapons'] as Map<String, dynamic>);
    }

    return PlayerWeapon(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      weaponId: row['weapon_id'] as String,
      durability: (row['durability'] as num?)?.toInt() ?? 100,
      isEquipped: (row['is_equipped'] as bool?) ?? false,
      acquiredAt: DateTime.parse(row['acquired_at'] as String),
      weapon: weapon,
    );
  }
}
