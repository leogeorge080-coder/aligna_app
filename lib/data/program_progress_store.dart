import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_progress.dart';
import '../persistence/prefs.dart';

class ProgramProgressStore {
  static const _kPrefix = 'aligna.programProgress.';

  static String _key(String programId) => '$_kPrefix$programId';

  Future<ProgramProgress?> read(String programId) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(programId));
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    return _fromJson(decoded);
  }

  Future<void> write(ProgramProgress progress) async {
    final sp = await SharedPreferences.getInstance();
    final jsonMap = _toJson(progress);
    await sp.setString(_key(progress.programId), json.encode(jsonMap));
  }

  Future<void> clear(String programId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key(programId));
  }

  Future<DateTime?> getProgramStartDate(String programId) async {
    return await Prefs.loadProgramStartDate(programId);
  }

  Future<void> ensureProgramStarted(String programId) async {
    await Prefs.ensureProgramStartDate(programId);
  }

  // ─────────────────────────────────────────────
  // JSON mapping
  // ─────────────────────────────────────────────

  Map<String, dynamic> _toJson(ProgramProgress p) => {
    'programId': p.programId,
    'lastCompletedDay': p.lastCompletedDay,
    'startedAt': p.startedAt.toUtc().toIso8601String(),
    'pausedAt': p.pausedAt?.toUtc().toIso8601String(),
    'finishedAt': p.finishedAt?.toUtc().toIso8601String(),
  };

  ProgramProgress _fromJson(Map<String, dynamic> m) {
    DateTime? parseDT(dynamic v) {
      if (v is! String || v.isEmpty) return null;
      return DateTime.tryParse(v)?.toUtc();
    }

    return ProgramProgress(
      programId: (m['programId'] as String?) ?? 'unknown_program',
      lastCompletedDay: (m['lastCompletedDay'] is num)
          ? (m['lastCompletedDay'] as num).toInt()
          : 0,
      startedAt: parseDT(m['startedAt']) ?? DateTime.now().toUtc(),
      pausedAt: parseDT(m['pausedAt']),
      finishedAt: parseDT(m['finishedAt']),
    );
  }
}
