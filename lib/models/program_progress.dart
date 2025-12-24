class ProgramProgress {
  final String programId;

  /// 1-based day index last completed by the user.
  /// Example: 0 means nothing completed yet.
  final int lastCompletedDay;

  /// When the user started the program (UTC recommended).
  final DateTime startedAt;

  /// If paused, store when. If null, not paused.
  final DateTime? pausedAt;

  /// If the user finished, store when. If null, not finished.
  final DateTime? finishedAt;

  const ProgramProgress({
    required this.programId,
    required this.lastCompletedDay,
    required this.startedAt,
    this.pausedAt,
    this.finishedAt,
  });

  bool get isPaused => pausedAt != null && finishedAt == null;
  bool get isFinished => finishedAt != null;

  ProgramProgress copyWith({
    int? lastCompletedDay,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? finishedAt,
    bool clearPausedAt = false,
    bool clearFinishedAt = false,
  }) {
    return ProgramProgress(
      programId: programId,
      lastCompletedDay: lastCompletedDay ?? this.lastCompletedDay,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
    );
  }
}
