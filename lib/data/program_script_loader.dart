import 'dart:convert';
import 'package:flutter/services.dart';

class ProgramScriptLoader {
  /// Loads a program script JSON from assets using an explicit asset path.
  static Future<Map<String, dynamic>> loadFromAssetPath(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Program script JSON must be an object at root.');
    }
    return decoded;
  }

  /// Convenience loader for Outcome Soothing v1.
  static Future<Map<String, dynamic>> loadOutcomeSoothingV1() {
    return loadFromAssetPath(
      'assets/data/program_scripts/outcome_soothing_7d.v1.json',
    );
  }
}
