import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

class AIAssistantService {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyBFl4n_-Q5LIt5xUBeGoA6SEC-n4hxJwck',
  );
  static const String _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-flash-latest',
  );

  static const String _systemPrompt =
      'You are the Royal Nest AI Assistant for a real-estate app. '
      'Help users with app navigation, plot booking, payments, installments, documents, queries, appointments, profile and notifications. '
      'Give practical, short, step-by-step answers with a professional tone. '
      'If a question is outside the app scope, politely redirect to Royal Nest app help only.';

  Future<String> reply({required String userMessage}) async {
    if (_geminiApiKey.trim().isEmpty) {
      throw StateError(
        'Gemini key is missing. Run with --dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }

    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': _geminiApiKey,
          },
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': _systemPrompt},
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': userMessage},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 300},
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String details = 'Gemini request failed (${response.statusCode}).';
      try {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final error = payload['error'];
        if (error is Map && error['message'] != null) {
          details = error['message'].toString();
        }
      } catch (_) {
        // Keep fallback message when response cannot be parsed.
      }
      throw Exception(details);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = payload['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw Exception('No assistant response received.');
    }

    final first = candidates.first;
    if (first is! Map) {
      throw Exception('Unexpected assistant response format.');
    }

    final content = first['content'];
    if (content is! Map) {
      throw Exception('Unexpected assistant response content format.');
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw Exception('Assistant returned no text parts.');
    }

    final firstPart = parts.first;
    if (firstPart is! Map) {
      throw Exception('Unexpected assistant response part format.');
    }

    final text = firstPart['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw Exception('Assistant returned an empty response.');
    }

    return text;
  }
}
