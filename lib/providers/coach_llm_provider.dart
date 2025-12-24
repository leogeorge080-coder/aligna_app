import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coach_reply.dart';
import '../services/llm_service.dart';
import '../utils/haptics.dart';
import 'app_providers.dart';
import 'micro_action_provider.dart';

final coachLlmProvider =
    StateNotifierProvider<CoachLlmNotifier, AsyncValue<CoachReply?>>(
      (ref) => CoachLlmNotifier(ref),
    );

class CoachLlmNotifier extends StateNotifier<AsyncValue<CoachReply?>> {
  CoachLlmNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> generateReply(String intention) async {
    final mood = ref.read(moodProvider);
    final lang = ref.read(languageProvider);

    if (mood == null || lang == null) return;

    final trimmed = intention.trim();
    if (trimmed.isEmpty) return;

    // Prevent double-tap duplicate calls
    if (state is AsyncLoading<CoachReply?>) return;

    state = const AsyncValue.loading();

    // ✅ Light haptic on "request start"
    try {
      await AppHaptics.light();
    } catch (_) {
      // Ignore haptics failures on some devices/emulators
    }

    // ✅ Mood-aware minimum typing time (calm pacing)
    int minTypingMs() {
      // Baseline by mood
      final base = switch (mood) {
        AlignaMood.stressed => 850,
        AlignaMood.tired => 950,
        AlignaMood.calm => 700,
        AlignaMood.motivated => 550,
      };

      // Add a little more time for longer user inputs (feels more "considered")
      final len = trimmed.length;
      final extra = (len <= 40)
          ? 0
          : (len <= 100)
          ? 150
          : (len <= 180)
          ? 260
          : 360;

      // Clamp so it never feels sluggish
      return (base + extra).clamp(450, 1300);
    }

    final sw = Stopwatch()..start();

    try {
      final reply = await LlmService.getCoachReply(
        intention: trimmed,
        mood: mood,
        language: lang,
      );

      sw.stop();

      // Ensure minimum "typing" time, even on fast responses.
      final minMs = minTypingMs();
      final remaining = minMs - sw.elapsedMilliseconds;
      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }

      // ✅ Commit reply
      state = AsyncValue.data(reply);

      // ✅ Offer micro-action INSIDE provider (Option B)
      // Only set it once per session (do not overwrite if user already has one).
      final currentText = ref.read(microActionTextProvider);
      final currentStatus = ref.read(microActionStatusProvider);

      final suggested = (reply.microAction?.trim().isNotEmpty ?? false)
          ? reply.microAction!.trim()
          : "Take 60 seconds: write one clear sentence of what you want more of.";

      final shouldOffer =
          (currentText == null || currentText.trim().isEmpty) &&
          (currentStatus == MicroActionStatus.none);

      if (shouldOffer) {
        offerMicroAction(ref, text: suggested);
      }

      // ✅ Success haptic when reply arrives (once)
      try {
        await AppHaptics.success();
      } catch (_) {}
    } catch (e, st) {
      sw.stop();
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);

    // Optional: clear micro-action when coach is cleared/refreshed
    // (Aligns with "refresh starts over" expectation.)
    resetMicroAction(ref);
  }
}
