import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/player_data.dart';
import '../models/quest.dart';

// ── Response model ────────────────────────────────────────

class GmResponse {
  final String message;
  final String action; // 'chat' | 'create_quest' | 'validate_quest'
  final Quest? quest;  // populated when action == 'create_quest'
  final String? questId; // populated when action == 'validate_quest'
  final bool? approved;  // populated when action == 'validate_quest'

  const GmResponse({
    required this.message,
    required this.action,
    this.quest,
    this.questId,
    this.approved,
  });

  factory GmResponse.fromJson(Map<String, dynamic> json) {
    Quest? quest;
    if (json['action'] == 'create_quest' && json['quest'] != null) {
      final q = json['quest'] as Map<String, dynamic>;
      final rank = (q['rank'] as String?) ?? 'F';
      final rawXp = (q['xpReward'] as num?)?.toInt() ?? 50;
      quest = Quest(
        id: 'gm_${DateTime.now().millisecondsSinceEpoch}',
        title: (q['title'] as String?) ?? 'Untitled Quest',
        description: (q['description'] as String?) ?? '',
        rank: rank,
        type: (q['type'] as String?) ?? 'side',
        xpReward: _clampXpToRank(rank, rawXp),
        classTag: (q['classTag'] as String?) ?? 'Any',
      );
    }

    return GmResponse(
      message: (json['message'] as String?) ?? '',
      action: (json['action'] as String?) ?? 'chat',
      quest: quest,
      questId: json['questId'] as String?,
      approved: json['approved'] as bool?,
    );
  }

  static int _clampXpToRank(String rank, int raw) {
    const ranges = {
      'F':   (25,   75),
      'E':   (75,   150),
      'D':   (150,  250),
      'C':   (250,  400),
      'B':   (400,  600),
      'A':   (600,  900),
      'S':   (900,  1500),
      'SS':  (1500, 2500),
      'SSS': (2500, 4000),
    };
    final range = ranges[rank] ?? (25, 75);
    return raw.clamp(range.$1, range.$2);
  }
}

// ── Typed exception ───────────────────────────────────────

class GuildMasterException implements Exception {
  final String message;
  const GuildMasterException(this.message);
  @override
  String toString() => message;
}

// ── Service ───────────────────────────────────────────────

class GuildMasterService {
  GuildMasterService();

  String _buildSystemPrompt(PlayerData livePlayer, List<Quest> liveQuests) {
    final activeQuests = liveQuests
        .where((q) => !q.isCompleted)
        .map((q) => '  - ${q.title} (Rank ${q.rank}, id: ${q.id})')
        .join('\n');

    return '''You are the Guild Master of Rizen — a real-life RPG.
The player is ${livePlayer.name}, Level ${livePlayer.level}, ${livePlayer.mainClass} / ${livePlayer.sideClass}.
Their active quests:
${activeQuests.isEmpty ? '  (none)' : activeQuests}

ACTION ROUTING — read this first, follow it exactly.

Your response JSON must include an "action" field. Pick the action using ONLY these rules:

1. "chat" — the DEFAULT. Use this for everything unless rule 2 or 3 fires.
   This includes: greetings, small talk, the player sharing what they did today, venting, asking questions, talking about past accomplishments, or anything that is not explicitly covered by rules 2 or 3.

2. "create_quest" — ONLY when the player explicitly asks you to create, assign, or start a quest, OR clearly describes something they WANT to do in the future.
   Trigger phrases: "I want to...", "I need to...", "Can you assign me...", "Give me a quest for...", "I plan to..."
   Do NOT trigger on past-tense statements like "I built 4 apps" or "I studied for 3 hours" — those are chat.

3. "validate_quest" — ONLY when the player explicitly claims they completed a SPECIFIC active quest by referencing its name or ID.
   Trigger phrases: "I finished [quest title]", "I completed the [quest]", "Mark [quest] as done", "[quest title] is done"
   Do NOT trigger on general statements about past work. "I coded today" is chat. "I finished the Networking Trial" is validation.
   If no active quest matches what the player describes, use "chat" and tell them in-character.

When in doubt, use "chat". It is always safe to chat. It is never safe to validate or create a quest by accident.

VOICE AND PERSONALITY

You are the Guild Master. Ancient, observant, sparing with words. You do not celebrate. You do not motivate. You document, you assess, you assign.

Rules for your voice:
- Short sentences. Two to four sentences max, usually less.
- No exclamation marks. Ever.
- No affirmations: never say "Great", "Excellent", "Good job", "Well done", "Impressive", "Nice", "Awesome", or any variant.
- Use guild language: quests, trials, rank, the path, the record, the dungeon, the arsenal.
- You may show dry wit, wry observation, or quiet acknowledgment. You are not a wall — you are a weathered veteran.
- When the player shares something (like "I built 4 apps"), you may briefly acknowledge it in-character ("Four constructs. The arsenal grows.") before moving on. Do not interrogate them for details unless you actually need information.
- When creating a quest: "A trial has been written." / "I have recorded your task."
- When the player is clearly stalling: "I have seen this before. Come back with results."
- You may occasionally say something in-world. Keep it brief. Keep it earned.

VALIDATION RULES (apply ONLY when action is "validate_quest")

These rules are strict. Do not soften them.
- Check if the claim is plausible. Is the description specific or vague?
- If too short or lacking real detail, set approved: false and ask for more evidence.
- A quest accepted less than 5 minutes ago should almost never be approved immediately.
  Respond: "You accepted this trial moments ago. I am not convinced. Prove it."
- When approving: "It is recorded." / "The trial is complete." / "Your rank is updated."
- When rejecting: "This is not sufficient." / "Return when the work is done."
- Demand specifics. Your word is final — use it judiciously.

XP guardrails (stay within these ranges):
F: 25–75 XP | E: 75–150 | D: 150–250 | C: 250–400
B: 400–600 | A: 600–900 | S: 900–1500 | SS: 1500–2500 | SSS: 2500–4000

Respond with valid JSON only. No markdown, no code fences, no explanation outside the JSON.''';
  }

  /// Sends [userMessage] to OpenAI, with [history] as prior turns.
  /// [history] should NOT include the current user message — this method appends it.
  /// [liveQuests] is the current quest list, used to build the system prompt fresh.
  Future<GmResponse> sendMessage(
    String userMessage,
    List<Map<String, String>> history,
    PlayerData livePlayer,
    List<Quest> liveQuests,
  ) async {
    final trimmedHistory = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    final messages = [
      {'role': 'system', 'content': _buildSystemPrompt(livePlayer, liveQuests)},
      ...trimmedHistory,
      {'role': 'user', 'content': userMessage},
    ];

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AppConstants.openAiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.openAiApiKey}',
        },
        body: jsonEncode({
        'model': AppConstants.openAiModel,
        'max_tokens': 1024,
        'messages': messages,
        'response_format': {
          'type': 'json_schema',
          'json_schema': {
            'name': 'gm_response',
            'strict': true,
            'schema': {
              'type': 'object',
              'properties': {
                'message': {'type': 'string'},
                'action': {
                  'type': 'string',
                  'enum': ['chat', 'create_quest', 'validate_quest'],
                },
                'quest': {
                  'anyOf': [
                    {'type': 'null'},
                    {
                      'type': 'object',
                      'properties': {
                        'title':       {'type': 'string'},
                        'description': {'type': 'string'},
                        'rank':        {'type': 'string', 'enum': ['F','E','D','C','B','A','S','SS','SSS']},
                        'type':        {'type': 'string', 'enum': ['daily','side','main']},
                        'xpReward':    {'type': 'integer'},
                        'classTag':    {'type': 'string'},
                      },
                      'required': ['title','description','rank','type','xpReward','classTag'],
                      'additionalProperties': false,
                    },
                  ],
                },
                'questId':  {'anyOf': [{'type': 'string'}, {'type': 'null'}]},
                'approved': {'anyOf': [{'type': 'boolean'}, {'type': 'null'}]},
              },
              'required': ['message','action','quest','questId','approved'],
              'additionalProperties': false,
            },
          },
        },
      }),
    ).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw GuildMasterException('The Guild Master took too long to respond. Try again.');
    }

    if (response.statusCode == 429) {
      throw GuildMasterException('The guild is overwhelmed. Rest and return shortly.');
    }
    if (response.statusCode == 401) {
      throw GuildMasterException('The Guild Master cannot be reached. (auth)');
    }
    if (response.statusCode >= 500) {
      throw GuildMasterException('The guildhall is dark. The servers rest. Try again later.');
    }
    if (response.statusCode != 200) {
      throw GuildMasterException('The Guild Master is unavailable. Try again.');
    }

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GuildMasterException('The Guild Master is unavailable. Try again.');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw GuildMasterException('The Guild Master is unavailable. Try again.');
    }
    final raw = choices.first['message']['content'] as String;

    // Strip markdown code fences if Claude wraps the JSON anyway
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'```json?\s*'), '')
          .replaceAll('```', '')
          .trim();
    }

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return GmResponse.fromJson(json);
    } catch (_) {
      throw GuildMasterException('The Guild Master spoke in riddles. Try again.');
    }
  }
}
