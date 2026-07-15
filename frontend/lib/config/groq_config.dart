class GroqConfig {
  static const String token = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String model = 'llama-3.3-70b-versatile';

  static bool get isConfigured => token.trim().isNotEmpty;
}