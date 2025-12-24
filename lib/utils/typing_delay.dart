import '../providers/app_providers.dart';

class TypingDelay {
  static int msForMood(AlignaMood mood) {
    return switch (mood) {
      AlignaMood.stressed => 700,
      AlignaMood.tired => 850,
      AlignaMood.calm => 550,
      AlignaMood.motivated => 420,
    };
  }

  static int msForTextLength(String text) {
    final len = text.trim().length;
    if (len <= 60) return 250;
    if (len <= 140) return 450;
    if (len <= 240) return 650;
    return 850;
  }

  /// Total pacing delay: mood baseline + content length.
  static Duration build({required AlignaMood mood, required String userInput}) {
    final base = msForMood(mood);
    final extra = msForTextLength(userInput);
    // Clamp to keep it calm, not annoying.
    final total = (base + extra).clamp(350, 1200);
    return Duration(milliseconds: total);
  }
}
