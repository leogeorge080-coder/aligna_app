import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coach_reply.dart';
import '../services/wiring_llm_service.dart';
import 'app_providers.dart';
import 'wiring_providers.dart';

final wiringLlmReplyProvider = FutureProvider.autoDispose<CoachReply>((
  ref,
) async {
  final day = ref.watch(wiringDayProvider) ?? 1;
  final core = ref.watch(wiringCoreIntentionProvider)?.trim() ?? '';
  final mood = ref.watch(moodProvider);
  final lang = ref.watch(languageProvider);

  if (core.isEmpty) {
    throw Exception('Missing core intention');
  }
  if (mood == null || lang == null) {
    throw Exception('Missing mood or language');
  }

  // Keep the provider alive while on screen, so it doesn’t refetch on minor rebuilds
  final link = ref.keepAlive();

  // AutoDispose cleanup after a short delay (optional)
  ref.onDispose(() => link.close());

  return WiringLlmService.getWiringReply(
    day: day,
    coreIntention: core,
    mood: mood,
    language: lang,
  );
});
