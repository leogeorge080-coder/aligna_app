import 'dart:convert';
import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────
/// Schema + parser for Program Script JSON
/// Locked schema: days → blocks → messagesByMood (with fallback)
/// ─────────────────────────────────────────────────────────────

class ScriptParseException implements Exception {
  final String message;
  final String path;
  ScriptParseException(this.message, {this.path = r'$'});
  @override
  String toString() => 'ScriptParseException($path): $message';
}

class ProgramScript {
  final String version;
  final String? programId;
  final List<ScriptDay> days;

  const ProgramScript({
    required this.version,
    required this.programId,
    required this.days,
  });

  /// Get a specific day (1-based). Returns null if missing.
  ScriptDay? getDay(int dayNumber) {
    for (final d in days) {
      if (d.day == dayNumber) {
        return d;
      }
    }
    return null;
  }

  /// Convenience: find a block by day + blockId.
  ScriptBlock? block({required int day, required String blockId}) {
    final d = getDay(day);
    return d?.block(blockId);
  }
}

class ScriptDay {
  final int day; // 1-based
  final String? title;
  final Map<String, dynamic>? resumeCopy;
  final List<ScriptBlock> blocks;

  const ScriptDay({
    required this.day,
    this.title,
    this.resumeCopy,
    required this.blocks,
  });

  ScriptBlock? block(String blockId) {
    for (final b in blocks) {
      if (b.blockId == blockId) {
        return b;
      }
    }
    return null;
  }
}

class ScriptBlock {
  final String blockId;
  final String? kind;
  final int maxLines;
  final int? estimatedMinutes;
  final String? intent;
  final String? llmPromptKey;
  final Map<String, dynamic>? microAction;
  final Map<String, dynamic>? reflection;
  final Map<String, List<String>> messagesByMood;

  const ScriptBlock({
    required this.blockId,
    required this.kind,
    required this.maxLines,
    this.estimatedMinutes,
    this.intent,
    this.llmPromptKey,
    this.microAction,
    this.reflection,
    required this.messagesByMood,
  });

  /// Resolve best messages for a mood key with fallback to 'fine'.
  List<String> resolveMessages(String moodKey) {
    final messages =
        messagesByMood[moodKey] ??
        messagesByMood['fine'] ??
        messagesByMood['calm'] ??
        messagesByMood['default'];
    if (messages == null) return const ['(Missing content)'];
    final cleaned = messages.where((s) => s.trim().isNotEmpty).toList();
    return cleaned.isEmpty ? const ['(Missing content)'] : cleaned;
  }
}

/// ─────────────────────────────────────────────────────────────
/// Parser + validator entry points
/// ─────────────────────────────────────────────────────────────

class ProgramScriptParser {
  /// Parse + validate from raw JSON string.
  static ProgramScript parse(String jsonText) {
    final dynamic decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw ScriptParseException('Root must be an object.');
    }
    return _parseRoot(decoded, path: r'$');
  }

  /// Validates only (returns list of errors instead of throwing).
  static List<String> validate(String jsonText) {
    try {
      parse(jsonText);
      return const [];
    } catch (e) {
      return [e.toString()];
    }
  }

  static ProgramScript _parseRoot(
    Map<String, dynamic> root, {
    required String path,
  }) {
    final version =
        _readString(root, 'schemaVersion', path, required: false) ?? '1.0';
    final programId = _readString(root, 'programId', path, required: false);

    final daysRaw = root['days'];
    if (daysRaw is! List) {
      throw ScriptParseException(
        'Missing or invalid "days" array.',
        path: '$path.days',
      );
    }

    final days = <ScriptDay>[];
    for (var i = 0; i < daysRaw.length; i++) {
      final item = daysRaw[i];
      if (item is! Map<String, dynamic>) {
        throw ScriptParseException(
          'Day must be an object.',
          path: '$path.days[$i]',
        );
      }
      days.add(_parseDay(item, path: '$path.days[$i]'));
    }

    if (days.isEmpty) {
      throw ScriptParseException(
        '"days" must not be empty.',
        path: '$path.days',
      );
    }

    // Validate unique day numbers and 1-based
    final seen = <int>{};
    for (final d in days) {
      if (d.day <= 0) {
        throw ScriptParseException(
          'Day number must be >= 1.',
          path: '$path.days(day=${d.day})',
        );
      }
      if (!seen.add(d.day)) {
        throw ScriptParseException(
          'Duplicate day number: ${d.day}.',
          path: '$path.days',
        );
      }
    }

    return ProgramScript(version: version, programId: programId, days: days);
  }

  static ScriptDay _parseDay(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final day = _readInt(json, 'day', path, required: true)!;
    final title = _readString(json, 'title', path, required: false);
    final resumeCopy = _readMap(json, 'resumeCopy', path, required: false);

    final blocksRaw = json['blocks'];
    if (blocksRaw is! List) {
      throw ScriptParseException(
        'Missing or invalid "blocks" array.',
        path: '$path.blocks',
      );
    }

    final blocks = <ScriptBlock>[];
    for (var i = 0; i < blocksRaw.length; i++) {
      final item = blocksRaw[i];
      if (item is! Map<String, dynamic>) {
        throw ScriptParseException(
          'Block must be an object.',
          path: '$path.blocks[$i]',
        );
      }
      blocks.add(_parseBlock(item, path: '$path.blocks[$i]'));
    }

    if (blocks.isEmpty) {
      throw ScriptParseException(
        '"blocks" must not be empty.',
        path: '$path.blocks',
      );
    }

    // Validate unique block ids within day
    final ids = <String>{};
    for (final b in blocks) {
      if (!ids.add(b.blockId)) {
        throw ScriptParseException(
          'Duplicate blockId "${b.blockId}" within day $day.',
          path: '$path.blocks',
        );
      }
    }

    return ScriptDay(
      day: day,
      title: title,
      resumeCopy: resumeCopy,
      blocks: blocks,
    );
  }

  static ScriptBlock _parseBlock(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final blockId = _readString(json, 'blockId', path, required: true)!;
    final kind = _readString(json, 'type', path, required: false);
    final maxLines = _readInt(json, 'maxLines', path, required: false) ?? 3;
    final estimatedMinutes = _readInt(
      json,
      'estimatedMinutes',
      path,
      required: false,
    );
    final intent = _readString(json, 'intent', path, required: false);
    final llmPromptKey = _readString(
      json,
      'llmPromptKey',
      path,
      required: false,
    );
    final microAction = _readMap(json, 'microAction', path, required: false);
    final reflection = _readMap(json, 'reflection', path, required: false);

    if (maxLines <= 0 || maxLines > 10) {
      throw ScriptParseException(
        '"maxLines" must be between 1 and 10.',
        path: '$path.maxLines',
      );
    }

    final mbmRaw = json['messagesByMood'];
    if (mbmRaw is! Map) {
      throw ScriptParseException(
        'Missing or invalid "messagesByMood" object.',
        path: '$path.messagesByMood',
      );
    }

    final mbm = <String, List<String>>{};
    for (final entry in mbmRaw.entries) {
      final k = entry.key;
      final v = entry.value;

      if (k is! String) {
        throw ScriptParseException(
          'Mood key must be a string.',
          path: '$path.messagesByMood',
        );
      }
      if (v is! List) {
        throw ScriptParseException(
          'Mood "$k" must be an array of strings.',
          path: '$path.messagesByMood.$k',
        );
      }

      final lines = <String>[];
      for (var i = 0; i < v.length; i++) {
        final item = v[i];
        if (item is! String) {
          throw ScriptParseException(
            'Mood "$k" must contain only strings.',
            path: '$path.messagesByMood.$k[$i]',
          );
        }
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) lines.add(trimmed);
      }

      // Allow empty arrays but we’ll enforce at least one fallback later.
      mbm[k.trim().toLowerCase()] = lines;
    }

    // Enforce fallback existence
    final hasFallback =
        _hasNonEmpty(mbm, 'fine') ||
        _hasNonEmpty(mbm, 'calm') ||
        _hasNonEmpty(mbm, 'default');

    if (!hasFallback) {
      throw ScriptParseException(
        'Block must include fallback messages in "fine" or "calm" or "default".',
        path: '$path.messagesByMood',
      );
    }

    return ScriptBlock(
      blockId: blockId,
      kind: kind,
      maxLines: maxLines,
      estimatedMinutes: estimatedMinutes,
      intent: intent,
      llmPromptKey: llmPromptKey,
      microAction: microAction,
      reflection: reflection,
      messagesByMood: mbm,
    );
  }

  static bool _hasNonEmpty(Map<String, List<String>> m, String k) {
    final v = m[k];
    return v != null && v.where((s) => s.trim().isNotEmpty).isNotEmpty;
  }

  static String? _readString(
    Map<String, dynamic> json,
    String key,
    String path, {
    required bool required,
  }) {
    final v = json[key];
    if (v == null) {
      if (required) {
        throw ScriptParseException('Missing "$key".', path: '$path.$key');
      }
      return null;
    }
    if (v is! String) {
      throw ScriptParseException(
        '"$key" must be a string.',
        path: '$path.$key',
      );
    }
    final s = v.trim();
    if (required && s.isEmpty) {
      throw ScriptParseException(
        '"$key" must not be empty.',
        path: '$path.$key',
      );
    }
    return s.isEmpty ? null : s;
  }

  static int? _readInt(
    Map<String, dynamic> json,
    String key,
    String path, {
    required bool required,
  }) {
    final v = json[key];
    if (v == null) {
      if (required) {
        throw ScriptParseException('Missing "$key".', path: '$path.$key');
      }
      return null;
    }
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    throw ScriptParseException('"$key" must be an int.', path: '$path.$key');
  }

  static Map<String, dynamic>? _readMap(
    Map<String, dynamic> json,
    String key,
    String path, {
    required bool required,
  }) {
    final v = json[key];
    if (v == null) {
      if (required) {
        throw ScriptParseException('Missing "$key".', path: '$path.$key');
      }
      return null;
    }
    if (v is! Map<String, dynamic>) {
      throw ScriptParseException(
        '"$key" must be an object.',
        path: '$path.$key',
      );
    }
    return v;
  }
}

/// Optional helper for logging validation errors without crashing release builds.
void debugValidateScript(String jsonText, {String label = 'script'}) {
  final errors = ProgramScriptParser.validate(jsonText);
  if (errors.isEmpty) {
    return;
  }
  debugPrint('[$label] Schema validation failed:\n${errors.join('\n')}');
}
