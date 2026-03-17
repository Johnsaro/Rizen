class Quest {
  final String id;
  final String title;
  final String description;
  final String rank; // F, E, D, C, B, A, S, SS, SSS
  final String type; // 'daily', 'main', 'side'
  final int xpReward;
  final String classTag; // e.g. 'Sec Analyst', 'Developer', 'Any'
  final bool isCompleted;
  final String deadline; // YYYY-MM-DD, empty = no deadline

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.rank,
    required this.type,
    required this.xpReward,
    required this.classTag,
    this.isCompleted = false,
    this.deadline = '',
  });

  Quest copyWith({String? id, bool? isCompleted, String? deadline}) {
    return Quest(
      id: id ?? this.id,
      title: title,
      description: description,
      rank: rank,
      type: type,
      xpReward: xpReward,
      classTag: classTag,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rank': rank,
        'type': type,
        'xpReward': xpReward,
        'classTag': classTag,
        'isCompleted': isCompleted,
        'deadline': deadline,
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        rank: json['rank'] as String,
        type: json['type'] as String,
        xpReward: (json['xpReward'] as num).toInt(),
        classTag: json['classTag'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        deadline: json['deadline'] as String? ?? '',
      );
}
