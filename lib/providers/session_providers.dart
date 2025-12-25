import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coach session stage.
/// UI rule: never stay in composing/loading indefinitely.
/// Any run must end in SessionStage.done (or idle after explicit reset).
enum SessionStage { idle, composing, loading, done }

/// Mood key used by ProgramScript schema:
/// "calm" | "stressed" | "tired" | "motivated"
final sessionMoodProvider = StateProvider<String?>((ref) => null);

final sessionStageProvider = StateProvider<SessionStage>(
  (ref) => SessionStage.idle,
);

final sessionIntentionProvider = StateProvider<String>((ref) => '');

/// Optional: lightweight debug label (e.g., current blockId) to inspect stuck states.
/// Safe to leave unused.
final sessionDebugLabelProvider = StateProvider<String?>((ref) => null);

/// Convenience: set mood (accepts null to clear).
void setSessionMood(WidgetRef ref, String? moodKey) {
  ref.read(sessionMoodProvider.notifier).state = moodKey;
}

/// Convenience: set intention (defaults to '').
void setSessionIntention(WidgetRef ref, String intention) {
  ref.read(sessionIntentionProvider.notifier).state = intention;
}

/// Convenience: set debug label (e.g., "day=1 block=morning").
void setSessionDebugLabel(WidgetRef ref, String? label) {
  ref.read(sessionDebugLabelProvider.notifier).state = label;
}

/// Hard reset to initial idle state.
/// Use this when program changes or user explicitly restarts.
void resetSession(WidgetRef ref) {
  ref.read(sessionMoodProvider.notifier).state = null;
  ref.read(sessionStageProvider.notifier).state = SessionStage.idle;
  ref.read(sessionIntentionProvider.notifier).state = '';
  ref.read(sessionDebugLabelProvider.notifier).state = null;

  // Also clear the AI reply state if you have it:
  // ref.read(coachMessageBufferProvider.notifier).clear();
  // ref.read(coachLlmProvider.notifier).clear();
}

/// Critical helper:
/// Wrap any coach pipeline run in this, so stage ALWAYS returns to done.
///
/// Typical usage:
/// await runWithSessionStage(ref, label: 'day=1 block=morning', run: () async {
///   ...emit fallback... await enhance... update messages...
/// });
Future<T?> runWithSessionStage<T>(
  WidgetRef ref, {
  String? label,
  required Future<T> Function() run,
}) async {
  final stage = ref.read(sessionStageProvider.notifier);

  if (label != null) {
    ref.read(sessionDebugLabelProvider.notifier).state = label;
  }

  stage.state = SessionStage.composing;

  try {
    final result = await run();
    return result;
  } catch (e, st) {
    // Never allow an exception to leave the stage stuck.
    if (kDebugMode) {
      debugPrint('Coach pipeline error: $e');
      debugPrintStack(stackTrace: st);
    }
    return null;
  } finally {
    // Absolute rule: do not remain in composing/loading.
    stage.state = SessionStage.done;

    // Optional: clear label once completed to reduce noise.
    ref.read(sessionDebugLabelProvider.notifier).state = null;
  }
}

/// Optional helpers if you want explicit transitions.
/// These are safe wrappers around stage updates.
void setStageComposing(WidgetRef ref) =>
    ref.read(sessionStageProvider.notifier).state = SessionStage.composing;

void setStageLoading(WidgetRef ref) =>
    ref.read(sessionStageProvider.notifier).state = SessionStage.loading;

void setStageDone(WidgetRef ref) =>
    ref.read(sessionStageProvider.notifier).state = SessionStage.done;
