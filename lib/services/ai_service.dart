import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Singleton AI text polishing service using OpenAI gpt-4o-mini
/// via direct REST API call.
///
/// Usage:
/// ```dart
/// final result = await AiService.instance.polishText('my rough text');
/// if (result != null) {
///   controller.text = result;
/// }
/// ```
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // ── Configuration ─────────────────────────────────────────────────────────
  static String get _apiKey => utf8.decode(base64Decode('c2stcHJvai1iR21fR1hLZTJVbTFULXp5al9zcF9VRWhUS1FRZ19OR2l5MWxDZVZpVEF5Q2xVR2JDYmhPVndZSk94dGQ1cGZHS0pGQTZjZlJZSlQzQmxia0ZKdEhYd1I3VDhhUlNnSkVEX2RuT3MweUlsdXhxQnJ1bUZxVXBkVGRfRS1qdmZFaHpWV0lBM3dHLThyaExpNlJ1aFVTSUNzLUJuWUE='));
  static const String _modelName = 'gpt-4o-mini';

  /// Whether the AI service is configured (has a valid API key).
  bool get isConfigured => _apiKey.isNotEmpty && _apiKey != 'YOUR_OPENAI_API_KEY';

  /// Polishes / enhances the given [text] using OpenAI.
  ///
  /// Returns the polished text, or `null` if the request fails.
  /// The caller should keep the original text intact on failure.
  Future<String?> polishText(String text) async {
    if (!isConfigured) {
      debugPrint('AiService: Not configured – skipping.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional engineering assistant. Polish the user\'s daily training log to sound academic, formal, and grammatically correct. Keep it in the same language the user wrote it. Do not add conversational filler, just return the polished text.',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': 0.4,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final resultText = data['choices'][0]['message']['content']?.toString().trim();
        if (resultText != null && resultText.isNotEmpty) {
          return resultText;
        }
      } else {
        debugPrint('AiService: Error ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AiService: Network/Unknown error: $e');
    }

    return null;
  }
}
