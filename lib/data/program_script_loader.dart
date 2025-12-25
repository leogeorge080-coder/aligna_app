import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../programs/script_schema.dart';

/// Loads program scripts from assets.
///
/// Key guarantees:
/// - Tries multiple candidate filenames (versioned first).
/// - Returns immediately on first success.
/// - Never strands UI by continuing after success.
/// - Throws only after all candidates fail.
class ProgramScriptLoader {
  const ProgramScriptLoader();

  /// Loads by `programId` (example: "money_safety_7d").
  ///
  /// Candidates tried (in order):
  /// 1) assets/data/program_scripts/<programId>.v1.json
  /// 2) assets/data/program_scripts/<programId>.json
  Future<ProgramScript> loadByProgramId(String programId) async {
    final candidates = <String>[
      'assets/data/program_scripts/$programId.v1.json',
      'assets/data/program_scripts/$programId.json',
    ];

    Object? lastError;

    for (final assetPath in candidates) {
      try {
        final raw = await _loadAssetText(assetPath);

        // IMPORTANT: In your repo, ProgramScriptParser.parse expects a String.
        final script = ProgramScriptParser.parse(raw);

        if (kDebugMode) {
          debugPrint('[SCRIPT] loaded OK: $assetPath (${raw.length} chars)');
        }

        return script;
      } catch (e, st) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('[SCRIPT] FAILED: $assetPath');
          debugPrint('$e');
          debugPrintStack(stackTrace: st);
        }
        // Continue to next candidate.
      }
    }

    throw Exception(
      'Unable to load script for programId="$programId". '
      'Tried: $candidates. Last error: $lastError',
    );
  }

  /// Loads from an exact asset path.
  Future<ProgramScript> loadFromAssetPath(String assetPath) async {
    final raw = await _loadAssetText(assetPath);
    return ProgramScriptParser.parse(raw);
  }

  Future<String> _loadAssetText(String assetPath) async {
    // Keep conservative: if the asset lookup hangs, we fail quickly.
    const timeout = Duration(seconds: 2);

    final raw = await rootBundle.loadString(assetPath).timeout(timeout);

    if (raw.trim().isEmpty) {
      throw Exception('Asset "$assetPath" exists but is empty.');
    }

    return raw;
  }
}
