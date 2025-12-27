import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'user_events_service.dart';

class NotificationManager {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> checkAndNotifyIfMissedSession({
    int lookbackDays = 14,
  }) async {
    await initialize();
    final events = await UserEventsService.fetchRecentEvents(
      type: 'session_start',
      limit: 50,
    );
    if (events.isEmpty) return;

    final now = DateTime.now();
    final recent = events
        .where(
          (e) => now.difference(e.createdAt).inDays <= lookbackDays,
        )
        .toList();
    if (recent.isEmpty) return;

    final avgHour = _averageHour(recent.map((e) => e.createdAt));
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEvents = recent.where(
      (e) => e.createdAt.isAfter(todayStart),
    );
    if (todayEvents.isNotEmpty) return;

    final target = DateTime(
      now.year,
      now.month,
      now.day,
      avgHour,
    ).add(const Duration(hours: 2));

    if (now.isAfter(target)) {
      await _showGentleNudge();
    }
  }

  static int _averageHour(Iterable<DateTime> times) {
    final hours = times.map((t) => t.hour).toList();
    if (hours.isEmpty) return 8;
    final sum = hours.reduce((a, b) => a + b);
    return (sum / hours.length).round().clamp(5, 11);
  }

  static Future<void> _showGentleNudge() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aligna_gentle_nudges',
        'Gentle Nudges',
        channelDescription: 'Soft reminders from Aligna',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(
        1101,
        'A gentle invitation',
        'Leo, your sanctuary is open whenever you are ready to return to yourself. No rush, just an invitation.',
        details,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationManager] Failed to show notification: $e');
      }
    }
  }
}
