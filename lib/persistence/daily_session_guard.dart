import 'package:shared_preferences/shared_preferences.dart';

class DailySessionGuard {
  static const _key = 'aligna_last_session_day';

  /// Returns true if user can start a new session today
  static Future<bool> canStartSession({required bool isPro}) async {
    // All users now have unlimited sessions (everyone is effectively Pro)
    return true;
  }

  /// Call when a session is fully completed
  static Future<void> markSessionCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _todayKey());
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
