import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/combat_question.dart';

class FlashcardService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<CombatQuestion>> fetchByWeapon(String weaponTag) async {
    final rows = await _client
        .from('flashcard_questions')
        .select()
        .eq('weapon_tag', weaponTag)
        .timeout(const Duration(seconds: 15));
    return (rows as List)
        .map((r) => CombatQuestion.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CombatQuestion>> fetchByClass(String classTag) async {
    final rows = await _client
        .from('flashcard_questions')
        .select()
        .eq('class_tag', classTag)
        .timeout(const Duration(seconds: 15));
    return (rows as List)
        .map((r) => CombatQuestion.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
