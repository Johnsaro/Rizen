/// A cached AI-generated lesson for a specific topic, path, and rank.
class Lesson {
  final String id;
  final String pathId;
  final String topic;
  final String rank;
  final String lessonContent; // Markdown lesson text
  final List<LessonQuiz> quizQuestions;
  final DateTime createdAt;

  const Lesson({
    required this.id,
    required this.pathId,
    required this.topic,
    required this.rank,
    required this.lessonContent,
    required this.quizQuestions,
    required this.createdAt,
  });

  factory Lesson.fromRow(Map<String, dynamic> row) {
    final rawQuiz = row['quiz_questions'];
    final questions = <LessonQuiz>[];
    if (rawQuiz is List) {
      for (final q in rawQuiz) {
        if (q is Map<String, dynamic>) {
          questions.add(LessonQuiz.fromJson(q));
        }
      }
    }

    return Lesson(
      id: row['id'] as String,
      pathId: row['path_id'] as String,
      topic: row['topic'] as String,
      rank: row['rank'] as String,
      lessonContent: (row['lesson_content'] as String?) ?? '',
      quizQuestions: questions,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

/// A single comprehension question attached to a lesson.
class LessonQuiz {
  final String question;
  final List<String> choices; // 4 choices
  final int correctIndex; // 0-3
  final String explanation;

  const LessonQuiz({
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  String get correctLetter => ['A', 'B', 'C', 'D'][correctIndex];

  factory LessonQuiz.fromJson(Map<String, dynamic> json) {
    return LessonQuiz(
      question: json['question'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((c) => c as String)
          .toList(),
      correctIndex: (json['correct_index'] as num).toInt(),
      explanation: (json['explanation'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'choices': choices,
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}
