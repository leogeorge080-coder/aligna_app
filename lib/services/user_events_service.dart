import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_event.dart';

class UserEventsService {
  static final _supabase = Supabase.instance.client;

  static Future<void> logEvent({
    required String eventType,
    Map<String, dynamic>? payload,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = <String, dynamic>{
      'user_id': userId,
      'event_type': eventType,
      'event_payload': payload ?? const <String, dynamic>{},
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
}
