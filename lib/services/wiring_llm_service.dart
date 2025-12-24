import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coach_reply.dart';
import '../providers/app_providers.dart';
import 'llm_service.dart';

class WiringLlmService {
  static String _cacheKey({
    required int day,
    required String coreIntention,
    required AlignaMood mood,
    required AlignaLanguage language,
  }) {
    // Keep key stable; trim intention; avoid huge keys by hashing lightly
    final t = coreIntention.trim();
    final intentKey = t.length <= 40 ? t : t.substring(0, 40);
    return 'wiring_llm_v1|day=$day|mood=${mood.name}|lang=${language.name}|intent=$intentKey';
  }

  static Future<CoachReply> getWiringReply({
    required int day,
    required String coreIntention,
    required AlignaMood mood,
    required AlignaLanguage language,
  }) async {
    final key = _cacheKey(
      day: day,
      coreIntention: coreIntention,
      mood: mood,
      language: language,
    );

    final sp = await SharedPreferences.getInstance();
    final cached = sp.getString(key);
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return CoachReply.fromJson(map);
      } catch (_) {
        // cache corrupted; fall through to fetch
      }
    }

    // Use your existing LlmService with wiring mode
    final reply = await LlmService.getCoachReply(
      intention: coreIntention,
      mood: mood,
      language: language,
      mode: 'wiring',
      day: day,
      coreIntention: coreIntention,
    );

    // Store cache (safe)
    try {
      await sp.setString(key, jsonEncode(reply.toJson()));
    } catch (_) {}

    return reply;
  }
}
