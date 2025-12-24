import '../models/aligna_mood.dart';
import '../models/program_session.dart';

typedef JsonMap = Map<String, dynamic>;

class ProgramSessionSelector {
  /// Returns a ProgramSession for a given program script JSON.
  ///
  /// [script] is the decoded JSON object (root).
  /// [day] is 1-based.
  /// [timeOfDay] selects morning/day_optional/evening.
  /// [mood] selects messagesByMood[mood].
  ///
  /// Safe fallbacks:
  /// - If mood list is missing/empty: tries 'fine', then first available mood list, else []
  /// - If microAction/reflection missing: returns null for those parts
  static ProgramSession getSession({
    required JsonMap script,
    required int day,
    required ProgramTimeOfDay timeOfDay,
    required AlignaMood mood,
  }) {
    final programId = _asString(script['programId']) ?? 'unknown_program';

    final days = _asList(script['days']);
    if (days == null || days.isEmpty) {
      return _emptySession(
        programId: programId,
        day: day,
        timeOfDay: timeOfDay,
      );
    }

    final dayObj = _findDay(days, day) ?? (days.first as JsonMap?);
    if (dayObj == null) {
      return _emptySession(
        programId: programId,
        day: day,
        timeOfDay: timeOfDay,
      );
    }

    final todKey = timeOfDay.jsonKey;
    final todObj = _asMap(dayObj[todKey]);
    if (todObj == null) {
      return _emptySession(
        programId: programId,
        day: day,
        timeOfDay: timeOfDay,
      );
    }

    final estimatedMinutes = _asInt(todObj['estimatedMinutes']) ?? 0;
    final intent = _asString(todObj['intent']) ?? '';

    // messagesByMood
    final messagesByMood = _asMap(todObj['messagesByMood']);
    final messages = _selectMoodMessages(messagesByMood, mood);

    // microAction (morning + day_optional)
    final microAction = _parseMicroAction(_asMap(todObj['microAction']));

    // reflection (evening)
    final reflection = _parseReflection(_asMap(todObj['reflection']));

    // resumeCopy lives at day root (not inside timeOfDay)
    final resumeCopyObj = _asMap(dayObj['resumeCopy']);
    final resumeCopy = ResumeCopy(
      neutral:
          _asString(resumeCopyObj?['neutral']) ??
          'Welcome back. We’ll continue from today—no catching up needed.',
      warm:
          _asString(resumeCopyObj?['warm']) ??
          'Good to have you here. We’ll pick up gently from today.',
    );

    return ProgramSession(
      programId: programId,
      day: _asInt(dayObj['day']) ?? day,
      timeOfDay: timeOfDay,
      estimatedMinutes: estimatedMinutes,
      intent: intent,
      messages: messages,
      microAction: microAction,
      reflection: reflection,
      resumeCopy: resumeCopy,
    );
  }

  // ─────────────────────────────────────────────
  // Internals
  // ─────────────────────────────────────────────

  static JsonMap? _findDay(List<dynamic> days, int day) {
    for (final d in days) {
      final m = _asMap(d);
      if (m == null) continue;
      final dd = _asInt(m['day']);
      if (dd == day) return m;
    }
    return null;
  }

  static List<String> _selectMoodMessages(
    JsonMap? messagesByMood,
    AlignaMood mood,
  ) {
    if (messagesByMood == null || messagesByMood.isEmpty) return const [];

    List<String> pick(String key) {
      final v = messagesByMood[key];
      final list = _asList(v);
      if (list == null) return const [];
      return list
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    // 1) requested mood
    final primary = pick(mood.jsonKey);
    if (primary.isNotEmpty) return primary;

    // 2) fallback to fine
    final fine = pick('fine');
    if (fine.isNotEmpty) return fine;

    // 3) fallback: first non-empty mood list
    for (final entry in messagesByMood.entries) {
      final candidate = pick(entry.key);
      if (candidate.isNotEmpty) return candidate;
    }

    return const [];
  }

  static MicroAction? _parseMicroAction(JsonMap? m) {
    if (m == null) return null;

    // If it's totally blank, treat as absent.
    final title = (_asString(m['title']) ?? '').trim();
    final instruction = (_asString(m['instruction']) ?? '').trim();
    final durationSeconds = _asInt(m['durationSeconds']) ?? 0;
    final isOptional = _asBool(m['isOptional']) ?? false;

    final hasRealContent = title.isNotEmpty || instruction.isNotEmpty;
    if (!hasRealContent && durationSeconds == 0) return null;

    return MicroAction(
      title: title,
      instruction: instruction,
      durationSeconds: durationSeconds,
      isOptional: isOptional,
    );
  }

  static Reflection? _parseReflection(JsonMap? m) {
    if (m == null) return null;

    final prompt = (_asString(m['prompt']) ?? '').trim();
    final examples =
        _asList(m['exampleAnswers'])
            ?.whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false) ??
        const [];

    if (prompt.isEmpty && examples.isEmpty) return null;

    return Reflection(prompt: prompt, exampleAnswers: examples);
  }

  static ProgramSession _emptySession({
    required String programId,
    required int day,
    required ProgramTimeOfDay timeOfDay,
  }) {
    return ProgramSession(
      programId: programId,
      day: day,
      timeOfDay: timeOfDay,
      estimatedMinutes: 0,
      intent: '',
      messages: const [],
      microAction: null,
      reflection: null,
      resumeCopy: const ResumeCopy(
        neutral:
            'Welcome back. We’ll continue from today—no catching up needed.',
        warm: 'Good to have you here. We’ll pick up gently from today.',
      ),
    );
  }

  static JsonMap? _asMap(dynamic v) => v is Map<String, dynamic> ? v : null;
  static List<dynamic>? _asList(dynamic v) => v is List ? v : null;
  static String? _asString(dynamic v) => v is String ? v : null;
  static int? _asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
  static bool? _asBool(dynamic v) => v is bool ? v : null;
}
