import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/prefs.dart';
import '../services/wiring_content.dart';
import '../services/daily_content_service.dart';
import '../models/wiring_program.dart';
import 'app_providers.dart';

String _todayKey() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

final wiringDayProvider = StateProvider<int?>((ref) => null);
final wiringLastDoneProvider = StateProvider<String?>((ref) => null);
final wiringCoreIntentionProvider = StateProvider<String?>((ref) => null);

final wiringContentProvider = FutureProvider<WiringDayContent?>((ref) async {
  final day = ref.watch(wiringDayProvider);
  if (day == null) return null;

  final languageCode = ref.watch(languageProvider) ?? 'en';

  // Try to fetch from Supabase first
  final dailyContent = await DailyContentService.fetchDayContent(
    programId: 'wiring',
    dayNumber: day,
    languageCode: languageCode,
  );

  if (dailyContent != null) {
    return WiringDayContent(
      day: dailyContent.dayNumber,
      title: dailyContent.title,
      focus: dailyContent.focus,
      question: dailyContent.question,
      microAction: dailyContent.microAction,
    );
  }

  // Fallback to hardcoded content if Supabase fails
  return WiringContent.forDay(day);
});

final wiringCanCompleteTodayProvider = Provider<bool>((ref) {
  final lastDone = ref.watch(wiringLastDoneProvider);
  final today = _todayKey();
  return lastDone != today;
});

class WiringController {
  WiringController(this.ref);
  final Ref ref;

  Future<void> load() async {
    final day = await Prefs.loadWiringDay();
    final last = await Prefs.loadWiringLastDoneDate();
    final core = await Prefs.loadWiringCoreIntention();
    ref.read(wiringDayProvider.notifier).state = day;
    ref.read(wiringLastDoneProvider.notifier).state = last;
    ref.read(wiringCoreIntentionProvider.notifier).state = core;
  }

  Future<void> start() async {
    await Prefs.startWiringProgram();
    await load();
  }

  Future<void> markDoneToday() async {
    final can = ref.read(wiringCanCompleteTodayProvider);
    if (!can) return;

    final day = ref.read(wiringDayProvider) ?? 1;
    final today = _todayKey();

    await Prefs.saveWiringLastDoneDate(today);

    // Advance day (max 21)
    final next = (day + 1).clamp(1, 21);
    await Prefs.saveWiringDay(next);

    await load();
  }

  Future<void> setCoreIntention(String text) async {
    await Prefs.saveWiringCoreIntention(text);
    ref.read(wiringCoreIntentionProvider.notifier).state = text;
  }
}

final wiringControllerProvider = Provider<WiringController>((ref) {
  return WiringController(ref);
});
