import 'package:flutter/services.dart';

class AppHaptics {
  static Future<void> tap() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }
}
