import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIAssistantService {
  static const String _prefsGeminiApiKey = 'ai.geminiApiKey';
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash',
  );

  static const String _clientSystemPrompt =
      'You are the Royal Nest AI Assistant for the client side of a real-estate app. '
      'You understand: properties & societies, plots, installments & payments, challans, '
      'lost & found + claims, 360 virtual tours, booking, notifications, and user profiles. '
      'Give short, direct, professional answers focused on Royal Nest workflows. '
      'Always suggest the next relevant in-app action. '
      'Avoid generic advice, avoid long explanations. '
      'If a question is outside the app scope, politely say you can only help with Royal Nest.';

  static const String _adminSystemPrompt =
      'You are the Royal Nest Admin AI Assistant. '
      'You respond only for admin users and admin modules. '
      'You understand: user management, property management, installments & payments, '
      'payment approvals, lost & found moderation, claims & reports, '
      'notifications/reminders, analytics/dashboard data, and admin workflows/actions. '
      'Give short, professional, to-the-point answers and always suggest the next admin action. '
      'Use the current screen context to guide actions. '
      'Do not provide client-facing guidance.';

  static const String _contextPrefix = 'App context (do not echo verbatim): ';

  Future<String> getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_prefsGeminiApiKey) ?? '').trim();
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsGeminiApiKey, apiKey.trim());
  }

  Future<void> clearSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsGeminiApiKey);
  }

  Future<String> _resolveApiKey() async {
    final compiledKey = _geminiApiKey.trim();
    if (compiledKey.isNotEmpty) {
      return compiledKey;
    }

    return getSavedApiKey();
  }

  Future<String> reply({
    required String userMessage,
    String? currentScreen,
    String? societyName,
    String? userRole,
  }) async {
    final prompt = userMessage.trim();
    if (prompt.isEmpty) {
      return 'Please type a question and I will help you.';
    }

    final contextLine = _buildContextLine(
      currentScreen: currentScreen,
      societyName: societyName,
      userRole: userRole,
    );

    final resolvedApiKey = await _resolveApiKey();

    // Keep chat usable even when remote AI key is not configured.
    if (resolvedApiKey.isEmpty) {
      return _localAssistantReply(
        prompt,
        currentScreen: currentScreen,
        societyName: societyName,
        userRole: userRole,
      );
    }

    final role = (userRole ?? 'client').toLowerCase();
    final systemPrompt = role == 'admin'
        ? _adminSystemPrompt
        : _clientSystemPrompt;

    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-goog-api-key': resolvedApiKey,
            },
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': systemPrompt},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': '$contextLine\n$prompt'},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 300},
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // If key/model is invalid or quota blocked, degrade gracefully.
        if (response.statusCode == 400 ||
            response.statusCode == 401 ||
            response.statusCode == 403 ||
            response.statusCode == 404 ||
            response.statusCode == 429) {
          return _localAssistantReply(
            prompt,
            currentScreen: currentScreen,
            societyName: societyName,
            userRole: userRole,
          );
        }

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
        return _localAssistantReply(prompt);
      }

      final first = candidates.first;
      if (first is! Map) {
        return _localAssistantReply(prompt);
      }

      final content = first['content'];
      if (content is! Map) {
        return _localAssistantReply(prompt);
      }

      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        return _localAssistantReply(prompt);
      }

      final textBuffer = StringBuffer();
      for (final part in parts) {
        if (part is Map && part['text'] != null) {
          final chunk = part['text'].toString().trim();
          if (chunk.isNotEmpty) {
            if (textBuffer.isNotEmpty) {
              textBuffer.write('\n');
            }
            textBuffer.write(chunk);
          }
        }
      }

      final text = textBuffer.toString().trim();
      if (text.isEmpty) {
        return _localAssistantReply(prompt);
      }

      return text;
    } on TimeoutException {
      return _localAssistantReply(
        prompt,
        currentScreen: currentScreen,
        societyName: societyName,
        userRole: userRole,
      );
    } on http.ClientException {
      return _localAssistantReply(
        prompt,
        currentScreen: currentScreen,
        societyName: societyName,
        userRole: userRole,
      );
    } catch (_) {
      return _localAssistantReply(
        prompt,
        currentScreen: currentScreen,
        societyName: societyName,
        userRole: userRole,
      );
    }
  }

  String _buildContextLine({
    String? currentScreen,
    String? societyName,
    String? userRole,
  }) {
    final parts = <String>[];
    if (currentScreen != null && currentScreen.trim().isNotEmpty) {
      parts.add('screen=$currentScreen');
    }
    if (societyName != null && societyName.trim().isNotEmpty) {
      parts.add('society=$societyName');
    }
    if (userRole != null && userRole.trim().isNotEmpty) {
      parts.add('role=$userRole');
    }
    return parts.isEmpty ? '' : '$_contextPrefix${parts.join(', ')}';
  }

  String _localAssistantReply(
    String userMessage, {
    String? currentScreen,
    String? societyName,
    String? userRole,
  }) {
    final q = userMessage.toLowerCase();
    final role = (userRole ?? 'client').toLowerCase();
    final location = societyName != null && societyName.trim().isNotEmpty
        ? ' in ${societyName.trim()}'
        : '';

    String action(String text) => 'Next: $text';

    if (role == 'admin') {
      if (q.contains('user') || q.contains('client') || q.contains('profile')) {
        return 'User management is handled in Clients.\n'
            '${action('Open Clients to review accounts, blocks, or details.')}';
      }

      if (q.contains('plot') ||
          q.contains('property') ||
          q.contains('listing')) {
        return 'Property and plot management lives in Plots.\n'
            '${action('Open Plots to add or edit listings.')}';
      }

      if (q.contains('payment') ||
          q.contains('installment') ||
          q.contains('challan')) {
        return 'Payments and installments are managed in Payments.\n'
            '${action('Open Payments to review dues and history.')}';
      }

      if (q.contains('approval') ||
          q.contains('manual') ||
          q.contains('proof')) {
        return 'Payment approvals are handled in Manual Payment Proofs.\n'
            '${action('Open Manual Payment Proofs and approve pending entries.')}';
      }

      if (q.contains('lost') || q.contains('found')) {
        return 'Lost & Found moderation is managed in Lost & Found.\n'
            '${action('Open Lost & Found to review active reports.')}';
      }

      if (q.contains('claim') || q.contains('report') || q.contains('query')) {
        return 'Claims and reports are tracked in Queries and Lost & Found.\n'
            '${action('Open Queries for reports or Lost & Found for claims.')}';
      }

      if (q.contains('document') || q.contains('verification')) {
        return 'Document verification happens in Documents.\n'
            '${action('Open Documents to approve or reject uploads.')}';
      }

      if (q.contains('appointment') || q.contains('meeting')) {
        return 'Appointments are managed in Appointments.\n'
            '${action('Open Appointments to confirm or reschedule.')}';
      }

      if (q.contains('notification') ||
          q.contains('reminder') ||
          q.contains('announcement')) {
        return 'Admin announcements are managed in Events.\n'
            '${action('Open Events to create a new notification.')}';
      }

      if (q.contains('analytics') ||
          q.contains('dashboard') ||
          q.contains('stats')) {
        return 'Analytics and KPIs are on the Admin Dashboard.\n'
            '${action('Open Dashboard to review today\'s metrics.')}';
      }

      return 'I can help with admin workflows: users, properties, payments, '
          'approvals, moderation, claims, notifications, and analytics.\n'
          '${action('Tell me the admin module or action you need.')}';
    }

    if (q.contains('installment') || q.contains('payment')) {
      return 'Payments and installments are managed from the Payments screen.\n'
          '${action('Go to Payments and open your plan for due months.')}';
    }

    if (q.contains('appointment') || q.contains('meeting')) {
      return 'Appointments can be requested and tracked from Appointments.\n'
          '${action('Open Appointments and pick a time slot.')}';
    }

    if (q.contains('document') || q.contains('upload')) {
      return 'Documents are uploaded and tracked in Documents.\n'
          '${action('Open Documents and upload the required files.')}';
    }

    if (q.contains('plot') || q.contains('booking')) {
      return 'Plots can be browsed and booked from Plots$location.\n'
          '${action('Open Plots and select a plot to continue booking.')}';
    }

    if (q.contains('query') || q.contains('complaint') || q.contains('issue')) {
      return 'Queries are handled in the Queries module.\n'
          '${action('Open Queries and submit a new request.')}';
    }

    if (q.contains('notification')) {
      return 'Notifications are available from the bell icon.\n'
          '${action('Open Notifications and review new updates.')}';
    }

    if (q.contains('challan') || q.contains('voucher')) {
      return 'Challan is available from the payment flow when you choose manual payment.\n'
          '${action('Open Payments and download the challan before uploading proof.')}';
    }

    if (q.contains('lost') || q.contains('found') || q.contains('claim')) {
      return 'Lost & Found is managed in the Lost & Found module.\n'
          '${action('Open Lost & Found and create or track a claim.')}';
    }

    if (q.contains('tour') || q.contains('360') || q.contains('virtual')) {
      return 'Virtual tours are available from Virtual Visit.\n'
          '${action('Open Virtual Visit and select a society tour.')}';
    }

    if (q.contains('profile') || q.contains('cnic') || q.contains('filer')) {
      return 'Profile and filer status are managed in Profile.\n'
          '${action('Open Profile to update your details.')}';
    }

    if (role == 'admin' &&
        (q.contains('approve') ||
            q.contains('reject') ||
            q.contains('admin'))) {
      return 'Admin actions are done from the Admin dashboard and modules.\n'
          '${action('Open Admin Home and select the relevant module.')}';
    }

    return 'I can help with RoyalNest tasks only (plots, payments, documents, queries, tours, and appointments).\n'
        '${action('Tell me what you want to do, and I will guide you.')}';
  }
}
