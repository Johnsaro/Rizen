import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../constants.dart';
import '../models/lesson.dart';
import 'supabase_service.dart';

/// Generates and caches AI-powered lessons for the Sect Library.
///
/// Flow: check cache → if miss, call OpenAI → save to cache → return.
class AiLessonService {
  /// Loads a lesson for [topic] at [rank] under [pathId]/[pathName]/[domain].
  /// Returns from cache if available; generates via AI otherwise.
  static Future<Lesson> getLesson({
    required String pathId,
    required String pathName,
    required String domain,
    required String topic,
    required String rank,
  }) async {
    // 1. Check cache first
    final cached = await SupabaseService.loadCachedLesson(
      pathId: pathId,
      topic: topic,
      rank: rank,
    );
    if (cached != null && cached.lessonContent.isNotEmpty) {
      return cached;
    }

    // 2. Generate via AI
    final result = await _generateLesson(
      pathName: pathName,
      domain: domain,
      topic: topic,
      rank: rank,
    );

    // 3. Cache and return
    return SupabaseService.saveCachedLesson(
      pathId: pathId,
      topic: topic,
      rank: rank,
      lessonContent: result.content,
      quizQuestions: result.questions,
    );
  }

  static Future<_GeneratedLesson> _generateLesson({
    required String pathName,
    required String domain,
    required String topic,
    required String rank,
  }) async {
    final systemPrompt = '''You are a cybersecurity instructor for the "$pathName" path (domain: $domain).

Generate a short, focused lesson on the topic: "$topic"
Difficulty level: Rank $rank (${_rankDescription(rank)})

The lesson should:
- Be 1-2 minutes of reading (roughly 200-400 words)
- Use clear, simple language — the reader is learning
- Include a practical example or analogy where helpful
- Use markdown formatting (headers, bold, code blocks where relevant)
- NOT include quiz questions in the lesson body

After the lesson, generate exactly 3 multiple-choice comprehension questions.
Each question must have exactly 4 choices (A, B, C, D) with 1 correct answer.
Questions should test understanding of the lesson content, not trivia.
Include a brief 1-sentence explanation for each correct answer.

Respond with valid JSON only. No markdown fences, no extra text.''';

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AppConstants.openAiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': AppConstants.openAiModel,
          'max_tokens': 2048,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Generate the lesson and quiz now.'},
          ],
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'lesson_and_quiz',
              'strict': true,
              'schema': {
                'type': 'object',
                'properties': {
                  'lesson_content': {'type': 'string'},
                  'quiz_questions': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'question': {'type': 'string'},
                        'choices': {
                          'type': 'array',
                          'items': {'type': 'string'},
                        },
                        'correct_index': {'type': 'integer'},
                        'explanation': {'type': 'string'},
                      },
                      'required': [
                        'question',
                        'choices',
                        'correct_index',
                        'explanation',
                      ],
                      'additionalProperties': false,
                    },
                  },
                },
                'required': ['lesson_content', 'quiz_questions'],
                'additionalProperties': false,
              },
            },
          },
        }),
      ).timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw LessonGenerationException(
        'The lesson scroll took too long to materialize. Try again.',
      );
    }

    debugPrint('[LessonService] Status: ${response.statusCode}');

    if (response.statusCode == 429) {
      throw LessonGenerationException(
        'The sect library is overwhelmed. Rest and return shortly.',
      );
    }
    if (response.statusCode != 200) {
      throw LessonGenerationException(
        'The lesson could not be prepared. Status ${response.statusCode}.',
      );
    }

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw LessonGenerationException(
          'The lesson scroll was unreadable. Try again.');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw LessonGenerationException(
          'The lesson scroll was empty. Try again.');
    }

    final raw = (choices.first['message']['content'] as String).trim();

    // Strip accidental code fences
    String cleaned = raw;
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'```json?\s*'), '')
          .replaceAll('```', '')
          .trim();
    }

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final content = json['lesson_content'] as String;
      final questions = (json['quiz_questions'] as List<dynamic>)
          .map((q) => LessonQuiz.fromJson(q as Map<String, dynamic>))
          .toList();

      if (content.trim().isEmpty) {
        throw LessonGenerationException('The lesson was empty. Try again.');
      }

      return _GeneratedLesson(content: content, questions: questions);
    } catch (e) {
      if (e is LessonGenerationException) rethrow;
      throw LessonGenerationException(
          'The lesson scroll was corrupted. Try again.');
    }
  }

  static String _rankDescription(String rank) {
    const desc = {
      'F': 'absolute beginner — foundational concepts only',
      'E': 'beginner — building on basics',
      'D': 'intermediate — real techniques and tools',
      'C': 'intermediate-advanced — deeper methodology',
      'B': 'advanced — professional-level techniques',
      'A': 'expert — complex scenarios and chaining',
      'S': 'master — cutting-edge, real-world operations',
    };
    return desc[rank] ?? 'beginner level';
  }
}

class _GeneratedLesson {
  final String content;
  final List<LessonQuiz> questions;
  const _GeneratedLesson({required this.content, required this.questions});
}

class LessonGenerationException implements Exception {
  final String message;
  const LessonGenerationException(this.message);
  @override
  String toString() => message;
}
