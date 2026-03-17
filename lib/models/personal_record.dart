enum PRCategory {
  discipline,
  build,
  learning,
  health,
  focus;

  static PRCategory fromString(String s) {
    switch (s) {
      case 'Discipline': return PRCategory.discipline;
      case 'Build':      return PRCategory.build;
      case 'Learning':   return PRCategory.learning;
      case 'Health':     return PRCategory.health;
      case 'Focus':      return PRCategory.focus;
      default:           return PRCategory.discipline;
    }
  }

  String get value {
    switch (this) {
      case PRCategory.discipline: return 'Discipline';
      case PRCategory.build:      return 'Build';
      case PRCategory.learning:   return 'Learning';
      case PRCategory.health:     return 'Health';
      case PRCategory.focus:      return 'Focus';
    }
  }
}

class PersonalRecord {
  final String id;
  final String title;
  final PRCategory category;
  final String description;
  final String mood;
  final String? metricType;
  final String? metricValue;
  final List<String> tags;
  final int? streakContext;
  final DateTime createdAt;

  const PersonalRecord({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.mood = '',
    this.metricType,
    this.metricValue,
    this.tags = const [],
    this.streakContext,
    required this.createdAt,
  });

  static PersonalRecord fromRow(Map<String, dynamic> row) {
    return PersonalRecord(
      id: row['id'] as String,
      title: row['title'] as String,
      category: PRCategory.fromString(row['category'] as String? ?? 'Discipline'),
      description: (row['description'] as String?) ?? '',
      mood: (row['mood'] as String?) ?? '',
      metricType: row['metric_type'] as String?,
      metricValue: row['metric_value'] as String?,
      tags: (row['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      streakContext: (row['streak_context'] as num?)?.toInt(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
