import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_context.dart';

class UserContextService {
  static final _supabase = Supabase.instance.client;

  static Future<UserContext> fetchContext() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return UserContext.empty();

    try {
      final response = await _supabase
          .from('user_context')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return UserContext.empty();
      return UserContext.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserContextService] Failed to fetch context: $e');
      }
      return UserContext.empty();
    }
  }

  static Future<UserContext> upsertContext({
    double? moodScore,
    String? lastTarotCard,
    String? activeFrequency,
    int? streakCount,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return UserContext.empty();

    final payload = <String, dynamic>{
      'user_id': userId,
      if (moodScore != null) 'mood_score': moodScore,
      if (lastTarotCard != null) 'last_tarot_card': lastTarotCard,
      if (activeFrequency != null) 'active_frequency': activeFrequency,
      if (streakCount != null) 'streak_count': streakCount,
    };

    if (payload.length == 1) {
      return fetchContext();
    }

    try {
      final response = await _supabase
          .from('user_context')
          .upsert(payload)
          .select('*')
          .single();

      return UserContext.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserContextService] Failed to upsert context: $e');
      }
      return UserContext.empty();
    }
  }
}
