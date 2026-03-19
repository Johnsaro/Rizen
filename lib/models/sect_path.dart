/// A path definition within a sect (e.g. Infiltrator under Shadow Arts).
/// Read-only — these are seeded in Supabase and never modified by the app.
class SectPath {
  final String id;
  final String sect;
  final String pathName;
  final String domain;
  final String description;

  /// Topics grouped by rank: { "F": ["topic1", ...], "D": [...], ... }
  final Map<String, List<String>> topicProgression;

  const SectPath({
    required this.id,
    required this.sect,
    required this.pathName,
    required this.domain,
    required this.description,
    required this.topicProgression,
  });

  /// All ranks that have topics defined, in order.
  static const rankOrder = ['F', 'E', 'D', 'C', 'B', 'A', 'S'];

  /// Topics available at [rank] and all ranks below it.
  List<String> topicsUpToRank(String rank) {
    final idx = rankOrder.indexOf(rank);
    if (idx < 0) return [];
    final topics = <String>[];
    for (var i = 0; i <= idx; i++) {
      topics.addAll(topicProgression[rankOrder[i]] ?? []);
    }
    return topics;
  }

  /// Topics for a specific rank only.
  List<String> topicsAtRank(String rank) =>
      topicProgression[rank] ?? [];

  factory SectPath.fromRow(Map<String, dynamic> row) {
    final raw = row['topic_progression'];
    final progression = <String, List<String>>{};
    if (raw is Map<String, dynamic>) {
      for (final entry in raw.entries) {
        progression[entry.key] = (entry.value as List<dynamic>)
            .map((e) => e as String)
            .toList();
      }
    }

    return SectPath(
      id: row['id'] as String,
      sect: row['sect'] as String,
      pathName: row['path_name'] as String,
      domain: row['domain'] as String,
      description: (row['description'] as String?) ?? '',
      topicProgression: progression,
    );
  }
}
