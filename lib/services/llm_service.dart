import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/coach_reply.dart';
import '../providers/app_providers.dart';

class LlmService {
  // Supabase Edge Function endpoint
  static const String _endpoint =
      'https://tfyzjqrgwjiturirjrpt.supabase.co/functions/v1/aligna-coach';

  // ⚠️ Use your SUPABASE anon public key (Dashboard → Settings → API → anon key)
  // Do NOT put your service_role key here.
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeXpqcXJnd2ppdHVyaXJqcnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzODU4NTQsImV4cCI6MjA4MTk2MTg1NH0.2GQt7Nu2XnhLNHaAm8BZ16-GM37vVzBay1ROxrs8inY';

  static Future<CoachReply> getCoachReply({
    required String intention,
    required AlignaMood mood,
    required AlignaLanguage language,
    String? mode,
    int? day,
    String? coreIntention,
  }) async {
    final resolvedMode = (mode == null || mode.trim().isEmpty)
        ? 'single'
        : mode;

    final payload = <String, dynamic>{
      'mode': resolvedMode,
      // ✅ ALWAYS include intention for single-mode contract safety
      'intention': intention.trim(),
      'mood': mood.name, // calm|stressed|tired|motivated
      'language': _langCode(language), // en|ar|hi|es
    };

    if (resolvedMode == 'wiring') {
      payload['day'] = day;
      payload['core_intention'] = coreIntention?.trim();
    }

    return _callCoachFunction(payload: payload);
  }

  /// Pro-only: 21-day wiring content.
  static Future<CoachReply> getWiringDay({
    required int day, // 1..21
    required String coreIntention,
    required AlignaMood mood,
    required AlignaLanguage language,
  }) async {
    return _callCoachFunction(
      payload: {
        'mode': 'wiring',
        'day': day,
        'core_intention': coreIntention,
        'mood': mood.name,
        'language': _langCode(language),
      },
    );
  }

  static Future<CoachReply> _callCoachFunction({
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse(_endpoint);

    // Optional hardening: remove null values
    payload.removeWhere((k, v) => v == null);

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Supabase expects both commonly:
        'Authorization': 'Bearer $_anonKey',
        'apikey': _anonKey,
      },
      body: jsonEncode(payload),
    );

    // DEBUG (temporary): log status + body to see real backend response
    debugPrint('[LLM] status=${res.statusCode}');
    debugPrint('[LLM] body=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('LLM HTTP ${res.statusCode}: ${res.body}');
    }

    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid JSON: ${res.body}');
    }

    // Support either:
    // 1) { "message": "..." }
    // 2) { "message": "...", "micro_action": "...", "closure": "..." }
    final message = (data['message'] ?? '').toString().trim();
    final micro = (data['micro_action'] ?? '').toString().trim();
    final closure = (data['closure'] ?? '').toString().trim();

    return CoachReply(
      message: message,
      microAction: micro.isEmpty ? null : micro,
      closure: closure.isEmpty ? null : closure,
    );
  }

  static String _langCode(AlignaLanguage language) {
    // Prefer a stable code mapping (avoid relying on enum.name if you ever rename)
    switch (language) {
      case AlignaLanguage.en:
        return 'en';
      case AlignaLanguage.ar:
        return 'ar';
      case AlignaLanguage.hi:
        return 'hi';
      case AlignaLanguage.es:
        return 'es';
    }
  }
}
