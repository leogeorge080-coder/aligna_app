import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/program_service.dart';
import 'active_program_provider.dart';
import 'program_progress_store_provider.dart';

class ProgramProgressUi {
  final String programId;
  final int day;
  final int totalDays;
  final bool isComplete;

  const ProgramProgressUi({
    required this.programId,
    required this.day,
    required this.totalDays,
    required this.isComplete,
  });
}

/// Computes "Day X of Y" for the active program.
/// Returns null if no active program is selected.
final programProgressProvider = FutureProvider<ProgramProgressUi?>((ref) async {
  // 1) Active program id
  final activeProgramId = await ref.watch(activeProgramIdProvider.future);
  if (activeProgramId == null) return null;

  // 2) Get program details from Supabase
  final program = await ProgramService.getProgramObjectById(activeProgramId);
  if (program == null) return null;

  final totalDays = program.durationDays;

  // 3) Start date (async)
  final store = ref.read(programProgressStoreProvider);

  // Safe: ensures start date exists (no-op if already set)
  // If you don't have ensureProgramStarted yet, add it to your store.
  await store.ensureProgramStarted(activeProgramId);

  final startDate = await store.getProgramStartDate(activeProgramId);

  // 4) Day computation (date-only)
  final now = DateTime.now();
  final todayOnly = DateTime(now.year, now.month, now.day);

  final startOnly = startDate == null
      ? todayOnly
      : DateTime(startDate.year, startDate.month, startDate.day);

  final diff = todayOnly.difference(startOnly).inDays + 1;
  final day = diff.clamp(1, totalDays);
  final isComplete = diff > totalDays;

  return ProgramProgressUi(
    programId: activeProgramId,
    day: day,
    totalDays: totalDays,
    isComplete: isComplete,
  );
});
