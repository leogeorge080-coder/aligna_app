import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/prefs.dart';
import 'program_progress_provider.dart';

class ResumeCopyResult {
  final String? text;
  final bool shouldMarkShown;

  const ResumeCopyResult({required this.text, required this.shouldMarkShown});
}

/// Pure provider: decides whether a resume line should be shown.
/// No writes / side effects happen here.
final resumeCopyProvider = FutureProvider<ResumeCopyResult>((ref) async {
  final progress = await ref.watch(programProgressProvider.future);
  if (progress == null) {
    return const ResumeCopyResult(text: null, shouldMarkShown: false);
  }
  if (progress.day <= 1) {
    return const ResumeCopyResult(text: null, shouldMarkShown: false);
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final last = await Prefs.loadLastResumeCopyDay();
  final shownToday =
      last != null &&
      last.year == today.year &&
      last.month == today.month &&
      last.day == today.day;

  if (shownToday) {
    return const ResumeCopyResult(text: null, shouldMarkShown: false);
  }

  return const ResumeCopyResult(
    text: 'Picking up where you left off.',
    shouldMarkShown: true,
  );
});

/// Side-effect action: mark resume copy as shown for today.
/// Call this from UI only when the resume line is actually rendered.
final markResumeCopyShownProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await Prefs.setLastResumeCopyDay(today);
  };
});
