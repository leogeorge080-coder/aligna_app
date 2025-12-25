import '../models/program_session.dart';
import '../programs/script_schema.dart';

typedef JsonMap = Map<String, dynamic>;

class ProgramSessionSelector {
  /// Map app mood keys (fine/tired_busy/curious etc.)
  /// into script mood keys:
  /// calm | stressed | tired | motivated | default
  static String _toScriptMoodKey(String mood) {
    final m = mood.trim().toLowerCase();

    // If caller already passes schema keys, keep them
    if (m == 'calm' || m == 'stressed' || m == 'tired' || m == 'motivated') {
      return m;
    }

    switch (m) {
      case 'fine':
      case 'ok':
      case 'neutral':
        return 'calm';

      case 'tired_busy':
      case 'tired-busy':
      case 'busy':
      case 'tired':
        return 'tired';

      case 'curious':
      case 'motivated':
      case 'ready':
        return 'motivated';

      case 'stressed':
      case 'anxious':
      case 'overwhelmed':
        return 'stressed';

      default:
        return 'default';
    }
  }

  static ProgramSession getSession({
    required ProgramScript script,
    required int day,
    required ProgramTimeOfDay timeOfDay,
    required String mood,
  }) {
    final programId = script.programId ?? 'unknown_program';

    final dayObj = script.getDay(day);
    if (dayObj == null) {
      return _emptySession(
        programId: programId,
        day: day,
        timeOfDay: timeOfDay,
      );
    }

    // Select block by time-of-day key; fallback to first available block.
    final todKey = timeOfDay.jsonKey;
    ScriptBlock? block = dayObj.block(todKey);
    block ??= (dayObj.blocks.isNotEmpty ? dayObj.blocks.first : null);

    if (block == null) {
      return _emptySession(
        programId: programId,
        day: day,
        timeOfDay: timeOfDay,
      );
    }

    final estimatedMinutes = block.estimatedMinutes ?? 0;
    final intent = block.intent ?? '';
    final llmPromptKey = block.llmPromptKey;

    // Normalize mood to script mood key
    final scriptMoodKey = _toScriptMoodKey(mood);

    // Use ScriptBlock resolver (already robust fallback in your schema file)
    final messages = block.resolveMessages(scriptMoodKey);

    final microAction = _parseMicroAction(block.microAction);
    final reflection = _parseReflection(block.reflection);

    final resumeCopy = ResumeCopy(
      neutral:
          _asString(dayObj.resumeCopy?['neutral']) ??
          'Welcome back. We’ll continue from today—no catching up needed.',
      warm:
          _asString(dayObj.resumeCopy?['warm']) ??
          'Good to have you here. We’ll pick up gently from today.',
    );

    return ProgramSession(
      programId: programId,
      day: dayObj.day,
      timeOfDay: timeOfDay,
      estimatedMinutes: estimatedMinutes,
      intent: intent,
      messages: messages.isEmpty
          ? const ['Let’s take this one step at a time.']
          : messages,
      microAction: microAction,
      reflection: reflection,
      resumeCopy: resumeCopy,
      llmPromptKey: llmPromptKey,
    );
  }

  // ─────────────────────────────────────────────

  static MicroAction? _parseMicroAction(JsonMap? m) {
    if (m == null) return null;

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
      messages: const ['Let’s take this one step at a time.'],
      microAction: null,
      reflection: null,
      resumeCopy: const ResumeCopy(
        neutral:
            'Welcome back. We’ll continue from today—no catching up needed.',
        warm: 'Good to have you here. We’ll pick up gently from today.',
      ),
      llmPromptKey: null,
    );
  }

  static List<dynamic>? _asList(dynamic v) => v is List ? v : null;
  static String? _asString(dynamic v) => v is String ? v : null;
  static int? _asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
  static bool? _asBool(dynamic v) => v is bool ? v : null;
}
