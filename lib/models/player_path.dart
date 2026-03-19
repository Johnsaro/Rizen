/// A player's progress on a specific path within their sect.
class PlayerPath {
  final String id;
  final String userId;
  final String pathId;
  final String rank;
  final double xp;

  /// Topics the player has studied (completed in Library).
  final List<String> studiedTopics;

  /// Per-topic accuracy: { "SQL injection basics": { "correct": 5, "total": 8 } }
  final Map<String, Map<String, int>> accuracyStats;

  final DateTime unlockedAt;
  final DateTime updatedAt;

  const PlayerPath({
    required this.id,
    required this.userId,
    required this.pathId,
    this.rank = 'F',
    this.xp = 0,
    this.studiedTopics = const [],
    this.accuracyStats = const {},
    required this.unlockedAt,
    required this.updatedAt,
  });

  /// XP needed to be eligible for rank-up trial at current rank.
  double get rankUpThreshold {
    const thresholds = {
      'F': 200.0,
      'E': 500.0,
      'D': 1000.0,
      'C': 2000.0,
      'B': 4000.0,
      'A': 8000.0,
      'S': 20000.0,
    };
    return thresholds[rank] ?? 200.0;
  }

  bool get canAttemptRankUp => xp >= rankUpThreshold;

  /// Check if a specific topic has been studied.
  bool hasStudied(String topic) => studiedTopics.contains(topic);

  /// Accuracy percentage for a topic (0.0–1.0). Returns null if no data.
  double? accuracyFor(String topic) {
    final stats = accuracyStats[topic];
    if (stats == null || (stats['total'] ?? 0) == 0) return null;
    return (stats['correct'] ?? 0) / stats['total']!;
  }

  PlayerPath copyWith({
    String? rank,
    double? xp,
    List<String>? studiedTopics,
    Map<String, Map<String, int>>? accuracyStats,
    DateTime? updatedAt,
  }) {
    return PlayerPath(
      id: id,
      userId: userId,
      pathId: pathId,
      rank: rank ?? this.rank,
      xp: xp ?? this.xp,
      studiedTopics: studiedTopics ?? this.studiedTopics,
      accuracyStats: accuracyStats ?? this.accuracyStats,
      unlockedAt: unlockedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PlayerPath.fromRow(Map<String, dynamic> row) {
    // Parse studied_topics
    final rawTopics = row['studied_topics'];
    final topics = <String>[];
    if (rawTopics is List) {
      for (final t in rawTopics) {
        topics.add(t as String);
      }
    }

    // Parse accuracy_stats
    final rawStats = row['accuracy_stats'];
    final stats = <String, Map<String, int>>{};
    if (rawStats is Map<String, dynamic>) {
      for (final entry in rawStats.entries) {
        if (entry.value is Map<String, dynamic>) {
          stats[entry.key] = (entry.value as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      }
    }

    return PlayerPath(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      pathId: row['path_id'] as String,
      rank: (row['rank'] as String?) ?? 'F',
      xp: (row['xp'] as num?)?.toDouble() ?? 0,
      studiedTopics: topics,
      accuracyStats: stats,
      unlockedAt: DateTime.parse(row['unlocked_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'user_id': userId,
        'path_id': pathId,
        'rank': rank,
        'xp': xp,
        'studied_topics': studiedTopics,
        'accuracy_stats': accuracyStats,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
