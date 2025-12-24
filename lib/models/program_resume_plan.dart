class ProgramResumePlan {
  /// The day we will show now (1-based).
  final int dayToShow;

  /// Whether we should show a gentle resume line before the session.
  final bool showResumeLine;

  /// The resume line key to pick (neutral/warm).
  final String resumeTone; // "neutral" | "warm"

  /// Informational (internal): number of calendar days since last completion.
  final int gapDays;

  const ProgramResumePlan({
    required this.dayToShow,
    required this.showResumeLine,
    required this.resumeTone,
    required this.gapDays,
  });
}
