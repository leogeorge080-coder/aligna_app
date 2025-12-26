import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationLevel {
  final double level; // 0.0 to 1.0
  final int totalSessions;
  final int completedSessions;

  const VibrationLevel({
    required this.level,
    required this.totalSessions,
    required this.completedSessions,
  });

  VibrationLevel copyWith({
    double? level,
    int? totalSessions,
    int? completedSessions,
  }) {
    return VibrationLevel(
      level: level ?? this.level,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
    );
  }
}

class VibrationLevelNotifier extends StateNotifier<VibrationLevel> {
  static const String _levelKey = 'vibration_level';
  static const String _totalSessionsKey = 'total_sessions';
  static const String _completedSessionsKey = 'completed_sessions';

  VibrationLevelNotifier()
    : super(
        const VibrationLevel(
          level: 0.0,
          totalSessions: 0,
          completedSessions: 0,
        ),
      ) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getDouble(_levelKey) ?? 0.0;
    final totalSessions = prefs.getInt(_totalSessionsKey) ?? 0;
    final completedSessions = prefs.getInt(_completedSessionsKey) ?? 0;

    state = VibrationLevel(
      level: level,
      totalSessions: totalSessions,
      completedSessions: completedSessions,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_levelKey, state.level);
    await prefs.setInt(_totalSessionsKey, state.totalSessions);
    await prefs.setInt(_completedSessionsKey, state.completedSessions);
  }

  Future<void> completeSession() async {
    final newCompleted = state.completedSessions + 1;
    final newTotal = state.totalSessions + 1;

    // Calculate new vibration level (increases with each completion)
    // Formula: base level + (completions * growth factor), capped at 1.0
    final growthFactor = 0.05; // 5% increase per session
    final newLevel = (state.level + growthFactor).clamp(0.0, 1.0);

    state = VibrationLevel(
      level: newLevel,
      totalSessions: newTotal,
      completedSessions: newCompleted,
    );

    await _saveToPrefs();
  }

  Future<void> resetProgress() async {
    state = const VibrationLevel(
      level: 0.0,
      totalSessions: 0,
      completedSessions: 0,
    );
    await _saveToPrefs();
  }
}

final vibrationLevelProvider =
    StateNotifierProvider<VibrationLevelNotifier, VibrationLevel>((ref) {
      return VibrationLevelNotifier();
    });
