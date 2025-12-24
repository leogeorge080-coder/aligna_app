import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionStage { idle, composing, loading, done }

final sessionMoodProvider = StateProvider<String?>((ref) => null);
// values: "calm" | "stressed" | "tired" | "motivated"

final sessionStageProvider = StateProvider<SessionStage>(
  (ref) => SessionStage.idle,
);

final sessionIntentionProvider = StateProvider<String>((ref) => '');

void resetSession(WidgetRef ref) {
  ref.read(sessionMoodProvider.notifier).state = null;
  ref.read(sessionStageProvider.notifier).state = SessionStage.idle;
  ref.read(sessionIntentionProvider.notifier).state = '';
  // Also clear the AI reply state if you have it:
  // ref.read(coachLlmProvider.notifier).clear();
}
