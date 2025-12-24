import '../models/program_progress.dart';
import '../models/program_resume_plan.dart';

class ProgramResumeLogic {
  /// Decides which day to show now, using gentle resumption:
  /// - Never forces catch-up
  /// - Never uses streak framing
  /// - If user missed days, we continue from the next logical day (lastCompletedDay + 1)
  ///
  /// Inputs:
  /// - [durationDays] from catalogue
  /// - [now] for testability (default DateTime.now())
  static ProgramResumePlan buildPlan({
    required ProgramProgress progress,
    required int durationDays,
    DateTime? now,
    bool preferWarmTone = true,
  }) {
    final tNow = (now ?? DateTime.now()).toUtc();

    // If finished: default behavior is show last day (or allow restart elsewhere).
    if (progress.isFinished) {
      return ProgramResumePlan(
        dayToShow: durationDays.clamp(1, durationDays),
        showResumeLine: false,
        resumeTone: preferWarmTone ? 'warm' : 'neutral',
        gapDays: 0,
      );
    }

    // If paused: we resume gently from next day (same logic), but show resume line.
    if (progress.isPaused) {
      final dayToShow = _nextDay(progress.lastCompletedDay, durationDays);
      final gap = _gapDaysSince(progress.pausedAt ?? progress.startedAt, tNow);
      return ProgramResumePlan(
        dayToShow: dayToShow,
        showResumeLine: true,
        resumeTone: preferWarmTone ? 'warm' : 'neutral',
        gapDays: gap,
      );
    }

    // Not paused, not finished.
    // "Soft resume": compute gap from last meaningful engagement time.
    // If user has completed at least one day, use startedAt + completion timing is unknown.
    // In v1, treat gap as days since startedAt if no better timestamps exist.
    //
    // Recommended: later you store lastActiveAt; for now we approximate.
    final anchor = progress.lastCompletedDay > 0
        ? progress.startedAt
        : progress.startedAt;
    final gapDays = _gapDaysSince(anchor, tNow);

    final dayToShow = _nextDay(progress.lastCompletedDay, durationDays);

    // Show resume line only if there's a meaningful gap OR user isn't on day 1.
    // This prevents unnecessary “welcome back” noise when user is flowing day-to-day.
    final showResumeLine = progress.lastCompletedDay > 0 && gapDays >= 1;

    return ProgramResumePlan(
      dayToShow: dayToShow,
      showResumeLine: showResumeLine,
      resumeTone: preferWarmTone ? 'warm' : 'neutral',
      gapDays: gapDays,
    );
  }

  /// Marks a day as completed (idempotent if already completed).
  /// Keeps it simple: lastCompletedDay increases only if [completedDay] is greater.
  static ProgramProgress markDayCompleted({
    required ProgramProgress progress,
    required int completedDay,
    required int durationDays,
    DateTime? now,
  }) {
    final tNow = (now ?? DateTime.now()).toUtc();
    final nextLast = completedDay > progress.lastCompletedDay
        ? completedDay
        : progress.lastCompletedDay;

    // If reached end, mark finished.
    if (nextLast >= durationDays) {
      return progress.copyWith(
        lastCompletedDay: durationDays,
        finishedAt: tNow,
        clearPausedAt: true,
      );
    }

    return progress.copyWith(lastCompletedDay: nextLast, clearPausedAt: true);
  }

  /// Pause the program.
  static ProgramProgress pause({
    required ProgramProgress progress,
    DateTime? now,
  }) {
    final tNow = (now ?? DateTime.now()).toUtc();
    if (progress.isFinished) return progress;
    if (progress.isPaused) return progress;
    return progress.copyWith(pausedAt: tNow);
  }

  /// Resume the program (clears pausedAt).
  static ProgramProgress resume({required ProgramProgress progress}) {
    if (!progress.isPaused) return progress;
    return progress.copyWith(clearPausedAt: true);
  }

  /// Restart program to day 1 (clears finished/paused, resets startedAt).
  static ProgramProgress restart({
    required ProgramProgress progress,
    DateTime? now,
  }) {
    final tNow = (now ?? DateTime.now()).toUtc();
    return ProgramProgress(
      programId: progress.programId,
      lastCompletedDay: 0,
      startedAt: tNow,
      pausedAt: null,
      finishedAt: null,
    );
  }

  static int _nextDay(int lastCompletedDay, int durationDays) {
    final raw = lastCompletedDay + 1;
    if (raw < 1) return 1;
    if (raw > durationDays) return durationDays;
    return raw;
  }

  static int _gapDaysSince(DateTime from, DateTime to) {
    final f = from.toUtc();
    final diff = to.difference(f);
    if (diff.isNegative) return 0;
    return diff.inDays;
  }
}
