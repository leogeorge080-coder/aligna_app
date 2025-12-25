enum ProgramTimeOfDay { morning, dayOptional, evening }

extension ProgramTimeOfDayKey on ProgramTimeOfDay {
  String get jsonKey => switch (this) {
    ProgramTimeOfDay.morning => 'morning',
    ProgramTimeOfDay.dayOptional => 'day_optional',
    ProgramTimeOfDay.evening => 'evening',
  };
}

class ProgramSession {
  final String programId;
  final int day; // 1-based
  final ProgramTimeOfDay timeOfDay;

  final int estimatedMinutes;
  final String intent;

  /// Coach lines for the selected mood.
  final List<String> messages;

  /// Present when morning/day_optional includes a microAction.
  final MicroAction? microAction;

  /// Present when evening includes reflection.
  final Reflection? reflection;

  /// Resume copy for gentle continuation.
  final ResumeCopy resumeCopy;

  /// Optional LLM prompt key for dynamic content.
  final String? llmPromptKey;

  const ProgramSession({
    required this.programId,
    required this.day,
    required this.timeOfDay,
    required this.estimatedMinutes,
    required this.intent,
    required this.messages,
    required this.microAction,
    required this.reflection,
    required this.resumeCopy,
    this.llmPromptKey,
  });
}

class MicroAction {
  final String title;
  final String instruction;
  final int durationSeconds;
  final bool isOptional;

  const MicroAction({
    required this.title,
    required this.instruction,
    required this.durationSeconds,
    required this.isOptional,
  });
}

class Reflection {
  final String prompt;
  final List<String> exampleAnswers;

  const Reflection({required this.prompt, required this.exampleAnswers});
}

class ResumeCopy {
  final String neutral;
  final String warm;

  const ResumeCopy({required this.neutral, required this.warm});
}
