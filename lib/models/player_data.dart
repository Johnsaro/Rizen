/// Cultivation realm definitions derived from player level.
/// Each realm spans a level range; within that range, ranks 1–9 are distributed.
class CultivationRealms {
  CultivationRealms._();

  static const List<({String name, int minLevel, int maxLevel, String breakthrough})> _realms = [
    (name: 'Mortal',                   minLevel: 1,  maxLevel: 5,  breakthrough: 'Qi detected. Binding initiated.'),
    (name: 'Qi Gathering',             minLevel: 6,  maxLevel: 15, breakthrough: 'Your meridians stir. The Dao notices you.'),
    (name: 'Foundation Establishment', minLevel: 16, maxLevel: 25, breakthrough: 'Foundation set. The heavens take note.'),
    (name: 'Core Formation',           minLevel: 26, maxLevel: 35, breakthrough: 'A golden core crystallizes. You have surpassed the masses.'),
    (name: 'Nascent Soul',             minLevel: 36, maxLevel: 45, breakthrough: 'Your soul stirs independently. Death itself hesitates.'),
    (name: 'Dao Seeking',              minLevel: 46, maxLevel: 50, breakthrough: 'You glimpse the Dao. The System... acknowledges you.'),
  ];

  /// Returns the realm record for a given overall level.
  static ({String name, int minLevel, int maxLevel, String breakthrough}) realmFor(int level) {
    for (final r in _realms) {
      if (level >= r.minLevel && level <= r.maxLevel) return r;
    }
    return _realms.last;
  }

  /// Computes the rank (1–9) within the realm for a given level.
  static int rankFor(int level) {
    final r = realmFor(level);
    final span = r.maxLevel - r.minLevel;
    if (span <= 0) return 9;
    final position = level - r.minLevel; // 0-based
    return ((position / span) * 8).round() + 1; // 1–9
  }

  /// "Early", "Middle", "Late", or "Peak" based on rank.
  static String subStageFor(int rank) {
    if (rank <= 3) return 'Early';
    if (rank <= 6) return 'Middle';
    if (rank <= 8) return 'Late';
    return 'Peak';
  }

  /// Full display string, e.g. "Qi Gathering — Late Stage (Rank 8)"
  static String displayFor(int level) {
    final r = realmFor(level);
    final rank = rankFor(level);
    final sub = subStageFor(rank);
    return '${r.name} — $sub Stage (Rank $rank)';
  }

  /// Short display, e.g. "Qi Gathering Lv 8"
  static String shortDisplayFor(int level) {
    final r = realmFor(level);
    final rank = rankFor(level);
    return '${r.name} Lv $rank';
  }

  /// Just the realm name, e.g. "Qi Gathering"
  static String nameFor(int level) => realmFor(level).name;
}

class PlayerData {
  final String name;
  final int level;
  final String mainPath;
  final String sect;
  final String activePath;
  final double qi;
  final int spiritStones;
  final Map<String, double> pathQi;
  final Map<String, int> pathLevel;
  final Map<String, int> inventory;
  final int daoHeartStreak;
  final int talismans;
  final String title;
  final int hp;
  final int maxHp;
  final String equippedWeapon;
  final Map<String, String> activePills;
  final Map<String, String> achievements;
  final String featuredAchievement;
  final int trialsCompleted;
  final int monstersKilled;
  final Map<String, String> equippedCosmetics;
  final Map<String, int> weaponDurability;
  final Map<String, String> weaponLastUsed;
  final List<String> equippedWeapons;
  final String realm;
  final int realmRank;
  final String daoHeartState;
  final bool qiDeviationActive;
  final String qiDeviationExpiry;
  final int qiDeviationTrials;

  const PlayerData({
    required this.name,
    required this.mainPath,
    this.sect = '',
    this.activePath = '',
    this.level = 1,
    this.qi = 0,
    this.spiritStones = 0,
    this.pathQi = const <String, double>{},
    this.pathLevel = const <String, int>{},
    this.inventory = const <String, int>{},
    this.daoHeartStreak = 0,
    this.talismans = 0,
    this.title = '',
    this.hp = 100,
    this.maxHp = 100,
    this.equippedWeapon = '',
    this.activePills = const <String, String>{},
    this.achievements = const <String, String>{},
    this.featuredAchievement = '',
    this.trialsCompleted = 0,
    this.monstersKilled = 0,
    this.equippedCosmetics = const <String, String>{},
    this.weaponDurability = const <String, int>{},
    this.weaponLastUsed = const <String, String>{},
    this.equippedWeapons = const <String>[],
    this.realm = 'Mortal',
    this.realmRank = 1,
    this.daoHeartState = 'Wavering',
    this.qiDeviationActive = false,
    this.qiDeviationExpiry = '',
    this.qiDeviationTrials = 0,
  });

  // ── Dao Heart state helpers ──────────────────────────────

  /// Derives the Dao Heart state name from current streak count.
  static String stateForStreak(int streak) {
    if (streak >= 30) return 'Immovable';
    if (streak >= 14) return 'Unyielding';
    if (streak >= 7)  return 'Firm';
    if (streak >= 3)  return 'Steady';
    return 'Wavering';
  }

  /// Qi bonus multiplier from Dao Heart state (0.0 to 0.20).
  static double qiBonusForStreak(int streak) {
    if (streak >= 30) return 0.20;
    if (streak >= 14) return 0.15;
    if (streak >= 7)  return 0.10;
    if (streak >= 3)  return 0.05;
    return 0.0;
  }

  /// Whether Qi Deviation is currently active (not expired).
  bool get isQiDeviationActive {
    if (!qiDeviationActive) return false;
    if (qiDeviationExpiry.isEmpty) return false;
    final expiry = DateTime.tryParse(qiDeviationExpiry);
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  /// Returns a copy with Qi Deviation cleared.
  PlayerData clearQiDeviation() => copyWith(
    qiDeviationActive: false,
    qiDeviationExpiry: '',
    qiDeviationTrials: 0,
  );

  // Overall maxQi scales with level: Lv1=150, Lv2=300, etc.
  double get maxQi => level * 150.0;

  // Per-path Qi threshold
  double pathMaxQi(String path) => (pathLevel[path] ?? 1) * 150.0;

  static const empty = PlayerData(
    name: '',
    mainPath: 'Shadow Arts',
    sect: '',
    activePath: '',
    daoHeartStreak: 0,
    talismans: 0,
    title: '',
    achievements: {},
    featuredAchievement: '',
    trialsCompleted: 0,
    monstersKilled: 0,
    equippedCosmetics: {},
    weaponDurability: {},
    weaponLastUsed: {},
    equippedWeapons: [],
    qiDeviationActive: false,
    qiDeviationExpiry: '',
    qiDeviationTrials: 0,
  );

  /// Returns true if [pillName] is currently active (not expired).
  /// Handles both ISO timestamps and `next_quest|TTL` format.
  bool isPillActive(String pillName) {
    final expiry = activePills[pillName];
    if (expiry == null) return false;
    if (expiry.startsWith('next_quest')) {
      final parts = expiry.split('|');
      if (parts.length < 2) return false;
      try {
        return DateTime.parse(parts[1]).isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }
    try {
      return DateTime.parse(expiry).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Returns a copy with all expired pills removed.
  PlayerData cleanExpiredPills() {
    final now = DateTime.now();
    final cleaned = Map<String, String>.from(activePills)
      ..removeWhere((_, expiry) {
        if (expiry.startsWith('next_quest')) {
          final parts = expiry.split('|');
          if (parts.length < 2) return false;
          try {
            return !DateTime.parse(parts[1]).isAfter(now);
          } catch (_) {
            return true;
          }
        }
        try {
          return !DateTime.parse(expiry).isAfter(now);
        } catch (_) {
          return true;
        }
      });
    if (cleaned.length == activePills.length) return this;
    return copyWith(activePills: cleaned);
  }

  /// Decrements inventory count for [itemName]. Removes key if count reaches 0.
  PlayerData useInstantItem(String itemName) {
    final newInventory = Map<String, int>.from(inventory);
    final count = newInventory[itemName] ?? 0;
    if (count <= 1) {
      newInventory.remove(itemName);
    } else {
      newInventory[itemName] = count - 1;
    }
    return copyWith(inventory: newInventory);
  }

  /// Adds a timed pill and decrements inventory.
  PlayerData activatePill(String pillName, String itemName, Duration duration) {
    final newPills = Map<String, String>.from(activePills);
    newPills[pillName] = DateTime.now().add(duration).toUtc().toIso8601String();
    return useInstantItem(itemName).copyWith(activePills: newPills);
  }

  /// Adds the Qi Surge marker with a 7-day TTL and decrements inventory.
  PlayerData activateQiSurge() {
    final newPills = Map<String, String>.from(activePills);
    final ttl = DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
    newPills['Qi Surge Pill'] = 'next_quest|$ttl';
    return useInstantItem('Qi Surge Pill').copyWith(activePills: newPills);
  }

  /// Adds [amount] Qi to the overall level and to the path track(s).
  /// If [pathTag] == 'Any', mainPath receives Qi.
  PlayerData addQi(int amount, {String pathTag = 'Any'}) {
    double xp = qi + amount;
    int lv = level;
    while (xp >= lv * 150.0) {
      xp -= lv * 150.0;
      lv++;
    }

    final newPathQi = Map<String, double>.from(pathQi);
    final newPathLevel = Map<String, int>.from(pathLevel);

    void applyPathQi(String path) {
      double pQi = (newPathQi[path] ?? 0.0) + amount;
      int pLv = newPathLevel[path] ?? 1;
      while (pQi >= pLv * 150.0) {
        pQi -= pLv * 150.0;
        pLv++;
      }
      newPathQi[path] = pQi;
      newPathLevel[path] = pLv;
    }

    if (pathTag == 'Any') {
      applyPathQi(mainPath);
    } else {
      applyPathQi(pathTag);
    }

    return PlayerData(
      name: name, mainPath: mainPath, sect: sect,
      activePath: activePath, level: lv, qi: xp, spiritStones: spiritStones,
      pathQi: newPathQi, pathLevel: newPathLevel, inventory: inventory,
      daoHeartStreak: daoHeartStreak, talismans: talismans, title: title,
      hp: hp, maxHp: maxHp, equippedWeapon: equippedWeapon,
      activePills: activePills, achievements: achievements,
      featuredAchievement: featuredAchievement, trialsCompleted: trialsCompleted,
      monstersKilled: monstersKilled, equippedCosmetics: equippedCosmetics,
      weaponDurability: weaponDurability, weaponLastUsed: weaponLastUsed,
      equippedWeapons: equippedWeapons,
      realm: CultivationRealms.nameFor(lv),
      realmRank: CultivationRealms.rankFor(lv),
      daoHeartState: daoHeartState,
      qiDeviationActive: qiDeviationActive,
      qiDeviationExpiry: qiDeviationExpiry,
      qiDeviationTrials: qiDeviationTrials,
    );
  }

  PlayerData addSpiritStones(int amount) {
    return copyWith(spiritStones: spiritStones + amount);
  }

  PlayerData buyItem(String item, int cost) {
    final newInventory = Map<String, int>.from(inventory);
    newInventory[item] = (newInventory[item] ?? 0) + 1;
    return copyWith(inventory: newInventory, spiritStones: spiritStones - cost);
  }

  PlayerData copyWith({
    String? name,
    String? mainPath,
    String? sect,
    String? activePath,
    int? level,
    double? qi,
    int? spiritStones,
    Map<String, double>? pathQi,
    Map<String, int>? pathLevel,
    Map<String, int>? inventory,
    int? daoHeartStreak,
    int? talismans,
    String? title,
    int? hp,
    int? maxHp,
    String? equippedWeapon,
    Map<String, String>? activePills,
    Map<String, String>? achievements,
    String? featuredAchievement,
    int? trialsCompleted,
    int? monstersKilled,
    Map<String, String>? equippedCosmetics,
    Map<String, int>? weaponDurability,
    Map<String, String>? weaponLastUsed,
    List<String>? equippedWeapons,
    String? realm,
    int? realmRank,
    String? daoHeartState,
    bool? qiDeviationActive,
    String? qiDeviationExpiry,
    int? qiDeviationTrials,
  }) {
    return PlayerData(
      name: name ?? this.name,
      mainPath: mainPath ?? this.mainPath,
      sect: sect ?? this.sect,
      activePath: activePath ?? this.activePath,
      level: level ?? this.level,
      qi: qi ?? this.qi,
      spiritStones: spiritStones ?? this.spiritStones,
      pathQi: pathQi ?? this.pathQi,
      pathLevel: pathLevel ?? this.pathLevel,
      inventory: inventory ?? this.inventory,
      daoHeartStreak: daoHeartStreak ?? this.daoHeartStreak,
      talismans: talismans ?? this.talismans,
      title: title ?? this.title,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      equippedWeapon: equippedWeapon ?? this.equippedWeapon,
      activePills: activePills ?? this.activePills,
      achievements: achievements ?? this.achievements,
      featuredAchievement: featuredAchievement ?? this.featuredAchievement,
      trialsCompleted: trialsCompleted ?? this.trialsCompleted,
      monstersKilled: monstersKilled ?? this.monstersKilled,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
      weaponDurability: weaponDurability ?? this.weaponDurability,
      weaponLastUsed: weaponLastUsed ?? this.weaponLastUsed,
      equippedWeapons: equippedWeapons ?? this.equippedWeapons,
      realm: realm ?? this.realm,
      realmRank: realmRank ?? this.realmRank,
      daoHeartState: daoHeartState ?? this.daoHeartState,
      qiDeviationActive: qiDeviationActive ?? this.qiDeviationActive,
      qiDeviationExpiry: qiDeviationExpiry ?? this.qiDeviationExpiry,
      qiDeviationTrials: qiDeviationTrials ?? this.qiDeviationTrials,
    );
  }
}
