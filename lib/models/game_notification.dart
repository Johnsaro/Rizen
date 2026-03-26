class GameNotification {
  final String id;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const GameNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  static GameNotification fromRow(Map<String, dynamic> row) {
    return GameNotification(
      id: row['id'] as String,
      message: row['message'] as String,
      type: NotificationType.fromString(row['type'] as String? ?? 'info'),
      isRead: (row['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}

enum NotificationType {
  checkin,
  questComplete,
  combatVictory,
  levelUp,
  streakMilestone,
  streakBreak,
  achievement,
  qiDeviation,
  info;

  static NotificationType fromString(String s) {
    switch (s) {
      case 'checkin':         return NotificationType.checkin;
      case 'quest_complete':  return NotificationType.questComplete;
      case 'combat_victory':  return NotificationType.combatVictory;
      case 'level_up':        return NotificationType.levelUp;
      case 'streak_milestone': return NotificationType.streakMilestone;
      case 'streak_break':    return NotificationType.streakBreak;
      case 'achievement':     return NotificationType.achievement;
      case 'qi_deviation':    return NotificationType.qiDeviation;
      default:                return NotificationType.info;
    }
  }

  String get value {
    switch (this) {
      case NotificationType.checkin:         return 'checkin';
      case NotificationType.questComplete:   return 'quest_complete';
      case NotificationType.combatVictory:   return 'combat_victory';
      case NotificationType.levelUp:         return 'level_up';
      case NotificationType.streakMilestone: return 'streak_milestone';
      case NotificationType.streakBreak:     return 'streak_break';
      case NotificationType.achievement:    return 'achievement';
      case NotificationType.qiDeviation:   return 'qi_deviation';
      case NotificationType.info:            return 'info';
    }
  }
}
