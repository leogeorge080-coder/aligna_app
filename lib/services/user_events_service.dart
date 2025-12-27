import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_event.dart';

class UserEventsService {
  static final _supabase = Supabase.instance.client;

  static Future<void> logEvent({
    required String eventType,
    Map<String, dynamic>? payload,
    String? tarotInsight,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = <String, dynamic>{
      'user_id': userId,
      'event_type': eventType,
      'event_payload': payload ?? const <String, dynamic>{},
      if (tarotInsight != null && tarotInsight.trim().isNotEmpty)
        'tarot_insight': tarotInsight.trim(),
    };

    try {
      await _supabase.from('user_events').insert(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserEventsService] Failed to log event: $e');
      }
    }
  }

  static Stream<List<UserEvent>> watchRecentEvents({int limit = 3}) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Stream<List<UserEvent>>.empty();
    }

    return _supabase
        .from('user_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (rows) => rows
              .map((row) => UserEvent.fromJson(row))
              .toList(growable: false),
        );
  }

  static Future<List<UserEvent>> fetchRecentEvents({
    int limit = 3,
    String? type,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const <UserEvent>[];

    try {
      var query = _supabase
          .from('user_events')
          .select('*')
          .eq('user_id', userId);
      if (type != null && type.trim().isNotEmpty) {
        query = query.eq('event_type', type.trim());
      }
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return response
          .map((row) => UserEvent.fromJson(row))
          .toList(growable: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserEventsService] Failed to fetch events: $e');
      }
      return const <UserEvent>[];
    }
  }
}
