class CombatQuestion {
  final String id;
  final String questionText;
  final List<String> options; // exactly 4
  final int correctIndex; // 0–3
  final String weaponTag;
  final String classTag;
  final int baseDamage;

  const CombatQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.weaponTag,
    required this.classTag,
    required this.baseDamage,
  });

  factory CombatQuestion.fromJson(Map<String, dynamic> json) {
    final correctLetter = (json['correct_option'] as String).toLowerCase();
    final rawIndex = 'abcd'.indexOf(correctLetter);
    // Fallback to 0 if correct_option is invalid — prevents timer-expiry
    // (chosenIndex = -1) from silently matching as correct.
    final correctIndex = rawIndex < 0 ? 0 : rawIndex;
    return CombatQuestion(
      id: json['id'] as String,
      questionText: json['question_text'] as String,
      options: [
        json['option_a'] as String,
        json['option_b'] as String,
        json['option_c'] as String,
        json['option_d'] as String,
      ],
      correctIndex: correctIndex,
      weaponTag: json['weapon_tag'] as String,
      classTag: json['class_tag'] as String,
      baseDamage: (json['base_damage'] as num?)?.toInt() ?? 100,
    );
  }
}
