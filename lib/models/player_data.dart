class PlayerData {
  final String name;
  final int level;
  final String mainClass;
  final String sideClass;
  final double currentXP;
  final int rep;
  final Map<String, double> classXp;
  final Map<String, int> classLevel;
  final Map<String, int> inventory;
  final int streak;
  final int shields;
  final String title;
  final int hp;
  final int maxHp;
  final String equippedWeapon;
  final Map<String, String> activeBuffs;
  final Map<String, String> achievements;
  final String featuredAchievement;
  final int questsCompleted;
  final int monstersKilled;
  final Map<String, String> equippedCosmetics;

  const PlayerData({
    required this.name,
    required this.mainClass,
    required this.sideClass,
    this.level = 1,
    this.currentXP = 0,
    this.rep = 0,
    this.classXp = const <String, double>{},
    this.classLevel = const <String, int>{},
    this.inventory = const <String, int>{},
    this.streak = 0,
    this.shields = 0,
    this.title = '',
    this.hp = 100,
    this.maxHp = 100,
    this.equippedWeapon = '',
    this.activeBuffs = const <String, String>{},
    this.achievements = const <String, String>{},
    this.featuredAchievement = '',
    this.questsCompleted = 0,
    this.monstersKilled = 0,
    this.equippedCosmetics = const <String, String>{},
  });

  // Overall maxXP scales with level: Lv1=150, Lv2=300, etc.
  double get maxXP => level * 150.0;

  // Per-class XP threshold
  double classMaxXP(String cls) => (classLevel[cls] ?? 1) * 150.0;

  static const empty = PlayerData(name: '', mainClass: 'Developer', sideClass: 'Sec Analyst', streak: 0, shields: 0, title: '', achievements: {}, featuredAchievement: '', questsCompleted: 0, monstersKilled: 0, equippedCosmetics: {});

  /// Returns true if [buffName] is currently active (not expired).
  /// Handles both ISO timestamps and `next_quest|TTL` format.
  bool isBuffActive(String buffName) {
    final expiry = activeBuffs[buffName];
    if (expiry == null) return false;
    if (expiry.startsWith('next_quest')) {
      // Format: 'next_quest|ISO_TTL' — check TTL if present
      final parts = expiry.split('|');
      if (parts.length < 2) return false; // malformed — treat as expired for safe cleanup
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

  /// Returns a copy with all expired buffs removed.
  PlayerData cleanExpiredBuffs() {
    final now = DateTime.now();
    final cleaned = Map<String, String>.from(activeBuffs)
      ..removeWhere((_, expiry) {
        if (expiry.startsWith('next_quest')) {
          final parts = expiry.split('|');
          if (parts.length < 2) return false; // legacy, keep
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
    if (cleaned.length == activeBuffs.length) return this;
    return copyWith(activeBuffs: cleaned);
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

  /// Adds a timed buff and decrements inventory.
  PlayerData activateBuff(String buffName, String itemName, Duration duration) {
    final newBuffs = Map<String, String>.from(activeBuffs);
    newBuffs[buffName] = DateTime.now().add(duration).toUtc().toIso8601String();
    return useInstantItem(itemName).copyWith(activeBuffs: newBuffs);
  }

  /// Adds the XP Surge marker with a 7-day TTL and decrements inventory.
  /// The marker is consumed on next quest completion. The TTL prevents
  /// permanent blocking if no quest is ever completed.
  PlayerData activateXPSurge() {
    final newBuffs = Map<String, String>.from(activeBuffs);
    final ttl = DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
    newBuffs['XP Surge'] = 'next_quest|$ttl';
    return useInstantItem('XP Surge').copyWith(activeBuffs: newBuffs);
  }

  /// Adds [amount] XP to the overall level and to the class track(s).
  /// If [classTag] == 'Any', both mainClass and sideClass receive XP.
  /// Otherwise only the matching class track is updated.
  PlayerData addXP(int amount, {String classTag = 'Any'}) {
    // Overall level progression
    double xp = currentXP + amount;
    int lv = level;
    while (xp >= lv * 150.0) {
      xp -= lv * 150.0;
      lv++;
    }

    // Class-track progression
    final newClassXp = Map<String, double>.from(classXp);
    final newClassLevel = Map<String, int>.from(classLevel);

    void applyClassXP(String cls) {
      double clsXp = (newClassXp[cls] ?? 0.0) + amount;
      int clsLv = newClassLevel[cls] ?? 1;
      while (clsXp >= clsLv * 150.0) {
        clsXp -= clsLv * 150.0;
        clsLv++;
      }
      newClassXp[cls] = clsXp;
      newClassLevel[cls] = clsLv;
    }

    if (classTag == 'Any') {
      applyClassXP(mainClass);
      applyClassXP(sideClass);
    } else {
      applyClassXP(classTag);
    }

    return PlayerData(
      name: name,
      mainClass: mainClass,
      sideClass: sideClass,
      level: lv,
      currentXP: xp,
      rep: rep,
      classXp: newClassXp,
      classLevel: newClassLevel,
      inventory: inventory,
      streak: streak,
      shields: shields,
      title: title,
      hp: hp,
      maxHp: maxHp,
      equippedWeapon: equippedWeapon,
      activeBuffs: activeBuffs,
      achievements: achievements,
      featuredAchievement: featuredAchievement,
      questsCompleted: questsCompleted,
      monstersKilled: monstersKilled,
      equippedCosmetics: equippedCosmetics,
    );
  }

  PlayerData addRep(int amount) {
    return PlayerData(
      name: name,
      mainClass: mainClass,
      sideClass: sideClass,
      level: level,
      currentXP: currentXP,
      rep: rep + amount,
      classXp: classXp,
      classLevel: classLevel,
      inventory: inventory,
      streak: streak,
      shields: shields,
      title: title,
      hp: hp,
      maxHp: maxHp,
      equippedWeapon: equippedWeapon,
      activeBuffs: activeBuffs,
      achievements: achievements,
      featuredAchievement: featuredAchievement,
      questsCompleted: questsCompleted,
      monstersKilled: monstersKilled,
      equippedCosmetics: equippedCosmetics,
    );
  }

  PlayerData buyItem(String item, int cost) {
    final newInventory = Map<String, int>.from(inventory);
    newInventory[item] = (newInventory[item] ?? 0) + 1;
    return PlayerData(
      name: name,
      mainClass: mainClass,
      sideClass: sideClass,
      level: level,
      currentXP: currentXP,
      rep: rep - cost,
      classXp: classXp,
      classLevel: classLevel,
      inventory: newInventory,
      streak: streak,
      shields: shields,
      title: title,
      hp: hp,
      maxHp: maxHp,
      equippedWeapon: equippedWeapon,
      activeBuffs: activeBuffs,
      achievements: achievements,
      featuredAchievement: featuredAchievement,
      questsCompleted: questsCompleted,
      monstersKilled: monstersKilled,
      equippedCosmetics: equippedCosmetics,
    );
  }

  PlayerData copyWith({
    String? name,
    String? mainClass,
    String? sideClass,
    int? level,
    double? currentXP,
    int? rep,
    Map<String, double>? classXp,
    Map<String, int>? classLevel,
    Map<String, int>? inventory,
    int? streak,
    int? shields,
    String? title,
    int? hp,
    int? maxHp,
    String? equippedWeapon,
    Map<String, String>? activeBuffs,
    Map<String, String>? achievements,
    String? featuredAchievement,
    int? questsCompleted,
    int? monstersKilled,
    Map<String, String>? equippedCosmetics,
  }) {
    return PlayerData(
      name: name ?? this.name,
      mainClass: mainClass ?? this.mainClass,
      sideClass: sideClass ?? this.sideClass,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      rep: rep ?? this.rep,
      classXp: classXp ?? this.classXp,
      classLevel: classLevel ?? this.classLevel,
      inventory: inventory ?? this.inventory,
      streak: streak ?? this.streak,
      shields: shields ?? this.shields,
      title: title ?? this.title,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      equippedWeapon: equippedWeapon ?? this.equippedWeapon,
      activeBuffs: activeBuffs ?? this.activeBuffs,
      achievements: achievements ?? this.achievements,
      featuredAchievement: featuredAchievement ?? this.featuredAchievement,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      monstersKilled: monstersKilled ?? this.monstersKilled,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
    );
  }
}
