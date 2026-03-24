class ExpenseTag {
  final String id;
  final String label;
  final int useCount;
  final DateTime createdAt;

  const ExpenseTag({
    required this.id,
    required this.label,
    this.useCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'use_count': useCount,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory ExpenseTag.fromMap(Map<String, dynamic> map) => ExpenseTag(
        id: map['id'] as String,
        label: map['label'] as String,
        useCount: (map['use_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}
