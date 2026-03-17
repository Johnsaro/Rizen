class AppConstants {
  // OpenAI API key — injected at build time via --dart-define=OPENAI_API_KEY=...
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String openAiModel = 'gpt-4o-mini';
  static const String openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';
}
