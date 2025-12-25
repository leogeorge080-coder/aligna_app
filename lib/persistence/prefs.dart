import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_providers.dart';

class Prefs {
  // ─────────────────────────────────────────────
  // Core keys
  // ─────────────────────────────────────────────
  static const _kLang = 'aligna_lang';

  // Mood keys (new window-aware)
  static const _kMood = 'aligna_mood';
  static const _kMoodWindow =
      'aligna_mood_window'; // morning|afternoon|evening|night
  static const _kMoodAnchorDate =
      'aligna_mood_anchor_date'; // yyyy-mm-dd (anchor)
  static const _kMoodWindowKey = 'aligna_mood_window_key';

  // Existing wiring keys (kept)
  static const _kWiringStartedAt = 'wiring_started_at';
  static const _kWiringCurrentDay = 'wiring_current_day';
  static const _kWiringLastDone = 'wiring_last_done_date';
  static const _wiringCoreIntentionKey = 'aligna_wiring_core_intention';

  // ─────────────────────────────────────────────
  // Program persistence
  // ─────────────────────────────────────────────
  static const _kActiveProgramId = 'aligna_active_program_id';
  static const _kProgramTimeOfDay =
      'aligna_program_time_of_day'; // morning|evening

  // ─────────────────────────────────────────────
  // Program progress keys
  // ─────────────────────────────────────────────
  static String _programStartKey(String programId) =>
      'program_start_$programId';
  static const _kLastResumeCopyDay = 'aligna_last_resume_copy_day';

  // Single helper to standardize prefs access
  static Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  // ─────────────────────────────────────────────
  // Small date helpers
  // ─────────────────────────────────────────────
  static String _yyyymmdd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // Greeting window definition:
  // - morning:   05:00–11:59
  // - afternoon: 12:00–16:59
  // - evening:   17:00–20:59
  // - night:     21:00–04:59 (crosses midnight)
  static String _currentGreetingWindow(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h <= 11) return 'morning';
    if (h >= 12 && h <= 16) return 'afternoon';
    if (h >= 17 && h <= 20) return 'evening';
    return 'night';
  }

  /// Anchor date makes "night" stable across midnight.
  /// Example:
  /// - 23:00 on 2025-12-24 => window night, anchor 2025-12-24
  /// - 02:00 on 2025-12-25 => window night, anchor 2025-12-24 (yesterday)
  static DateTime _anchorDateForWindow(DateTime now) {
    final win = _currentGreetingWindow(now);
    if (win != 'night') {
      return DateTime(now.year, now.month, now.day);
    }
    // If after midnight (0–4), anchor belongs to previous day.
    if (now.hour <= 4) {
      final prev = now.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day);
    }
    // 21–23 anchors to today
    return DateTime(now.year, now.month, now.day);
  }

  static String _windowKeyNow(DateTime now) {
    final h = now.hour;
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final bucket = (h >= 5 && h < 12)
        ? 'morning'
        : (h >= 12 && h < 17)
        ? 'afternoon'
        : (h >= 17 && h < 21)
        ? 'evening'
        : 'night';

    return '${bucket}_$dayKey';
  }

  // ─────────────────────────────────────────────
  // Language
  // ─────────────────────────────────────────────

  static Future<void> saveLang(AlignaLanguage lang) async {
    final p = await _sp();
    await p.setString(_kLang, lang.name);
  }

  static Future<AlignaLanguage?> loadLang() async {
    final p = await _sp();
    final s = p.getString(_kLang);
    if (s == null) return null;
    for (final v in AlignaLanguage.values) {
      if (v.name == s) return v;
    }
    return null;
  }

  /// Optional helper if you want “default English” behaviour:
  /// Call this once during bootstrap if you no longer want LanguageSelect as mandatory.
  static Future<AlignaLanguage> ensureLangOrDefaultEnglish() async {
    final existing = await loadLang();
    if (existing != null) return existing;
    await saveLang(AlignaLanguage.en);
    return AlignaLanguage.en;
  }

  // ─────────────────────────────────────────────
  // Mood (window-aware)
  // ─────────────────────────────────────────────

  /// Saves mood for the *current greeting window* (morning/afternoon/evening/night)
  /// and stores an anchor date so “night” survives across midnight.
  static Future<void> saveMoodForNow(AlignaMood mood) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMood, mood.name);
    await p.setString(_kMoodWindowKey, _windowKeyNow(DateTime.now()));
  }

  static Future<AlignaMood?> loadMoodForNow() async {
    final p = await SharedPreferences.getInstance();
    final moodStr = p.getString(_kMood);
    final key = p.getString(_kMoodWindowKey);

    if (moodStr == null || key == null) return null;

    final nowKey = _windowKeyNow(DateTime.now());
    if (key != nowKey) return null;

    // Parse back to enum
    for (final m in AlignaMood.values) {
      if (m.name == moodStr) return m;
    }
    return null;
  }

  /// Loads mood only if it matches the *current greeting window*.
  /// Returns null if mood is missing OR from an older window.
  static Future<AlignaMood?> loadMoodIfValidNow() async {
    final p = await _sp();

    final moodStr = p.getString(_kMood);
    final windowStr = p.getString(_kMoodWindow);
    final anchorStr = p.getString(_kMoodAnchorDate);

    if (moodStr == null || moodStr.trim().isEmpty) return null;
    if (windowStr == null || windowStr.trim().isEmpty) return null;
    if (anchorStr == null || anchorStr.trim().isEmpty) return null;

    final now = DateTime.now();
    final expectedWindow = _currentGreetingWindow(now);
    final expectedAnchor = _yyyymmdd(_anchorDateForWindow(now));

    if (windowStr != expectedWindow) return null;
    if (anchorStr != expectedAnchor) return null;

    for (final v in AlignaMood.values) {
      if (v.name == moodStr) return v;
    }
    return null;
  }

  /// Backwards-compatible: loads whatever is saved in _kMood without window checks.
  /// Prefer loadMoodIfValidNow() for your “mood until next greeting” requirement.
  static Future<AlignaMood?> loadMoodRaw() async {
    final p = await _sp();
    final s = p.getString(_kMood);
    if (s == null) return null;
    for (final v in AlignaMood.values) {
      if (v.name == s) return v;
    }
    return null;
  }

  static Future<void> clearMood() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kMood);
    await p.remove(_kMoodWindowKey);
  }

  // Additional mood methods
  static Future<void> saveMood(String mood) async {
    final p = await _sp();
    await p.setString(_kMood, mood);
  }

  static Future<String?> loadMood() async {
    final p = await _sp();
    return p.getString(_kMood);
  }

  static Future<void> saveMoodWindowKey(String key) async {
    final p = await _sp();
    await p.setString(_kMoodWindow, key);
  }

  static Future<String?> loadMoodWindowKey() async {
    final p = await _sp();
    return p.getString(_kMoodWindow);
  }

  // ─────────────────────────────────────────────
  // Wiring program (existing)
  // ─────────────────────────────────────────────

  static Future<void> startWiringProgram() async {
    final p = await _sp();
    await p.setString(_kWiringStartedAt, DateTime.now().toIso8601String());
    await p.setInt(_kWiringCurrentDay, 1);
    await p.remove(_kWiringLastDone);
  }

  static Future<int?> loadWiringDay() async {
    final p = await _sp();
    return p.getInt(_kWiringCurrentDay);
  }

  static Future<String?> loadWiringLastDoneDate() async {
    final p = await _sp();
    return p.getString(_kWiringLastDone);
  }

  static Future<void> saveWiringDay(int day) async {
    final p = await _sp();
    await p.setInt(_kWiringCurrentDay, day.clamp(1, 21));
  }

  static Future<void> saveWiringLastDoneDate(String yyyymmdd) async {
    final p = await _sp();
    await p.setString(_kWiringLastDone, yyyymmdd);
  }

  static Future<void> clearWiringProgram() async {
    final p = await _sp();
    await p.remove(_kWiringStartedAt);
    await p.remove(_kWiringCurrentDay);
    await p.remove(_kWiringLastDone);
    await p.remove(_wiringCoreIntentionKey);
  }

  static Future<String?> loadWiringCoreIntention() async {
    final p = await _sp();
    final value = p.getString(_wiringCoreIntentionKey);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  static Future<void> saveWiringCoreIntention(String text) async {
    final p = await _sp();
    final value = text.trim();
    if (value.isEmpty) {
      await p.remove(_wiringCoreIntentionKey);
    } else {
      await p.setString(_wiringCoreIntentionKey, value);
    }
  }

  // ─────────────────────────────────────────────
  // Active program + time of day
  // ─────────────────────────────────────────────

  static Future<void> setActiveProgramId(String programId) async {
    final p = await _sp();
    await p.setString(_kActiveProgramId, programId.trim());
  }

  static Future<String?> loadActiveProgramId() async {
    final p = await _sp();
    final s = p.getString(_kActiveProgramId);
    if (s == null) return null;
    final v = s.trim();
    return v.isEmpty ? null : v;
  }

  static Future<void> clearActiveProgramId() async {
    final p = await _sp();
    await p.remove(_kActiveProgramId);
  }

  /// Stores either "morning" or "evening". Any other value clears the key.
  static Future<void> setProgramTimeOfDay(String value) async {
    final p = await _sp();
    final v = value.trim().toLowerCase();
    if (v != 'morning' && v != 'evening') {
      await p.remove(_kProgramTimeOfDay);
      return;
    }
    await p.setString(_kProgramTimeOfDay, v);
  }

  /// Defaults to "morning" if unset/invalid.
  static Future<String> getProgramTimeOfDay() async {
    final p = await _sp();
    final v = p.getString(_kProgramTimeOfDay);
    if (v == 'evening') return 'evening';
    return 'morning';
  }

  static Future<void> clearProgramTimeOfDay() async {
    final p = await _sp();
    await p.remove(_kProgramTimeOfDay);
  }

  // ─────────────────────────────────────────────
  // Program progress (Day X of Y + resume-once-per-day)
  // ─────────────────────────────────────────────

  /// Ensures the start date is saved once (date-only). Safe to call repeatedly.
  static Future<void> ensureProgramStartDate(String programId) async {
    final p = await _sp();
    final key = _programStartKey(programId);
    final s = p.getString(key);
    if (s != null && s.trim().isNotEmpty) return;

    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    await p.setString(key, dateOnly.toIso8601String());
  }

  /// Loads the program start date (date-only). Returns null if unset/invalid.
  static Future<DateTime?> loadProgramStartDate(String programId) async {
    final p = await _sp();
    final s = p.getString(_programStartKey(programId));
    if (s == null || s.trim().isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static Future<void> clearProgramStartDate(String programId) async {
    final p = await _sp();
    await p.remove(_programStartKey(programId));
  }

  /// Marks that the resume microcopy has been shown for this calendar day.
  static Future<void> setLastResumeCopyDay(DateTime day) async {
    final p = await _sp();
    final d = DateTime(day.year, day.month, day.day).toIso8601String();
    await p.setString(_kLastResumeCopyDay, d);
  }

  /// Loads the last day resume microcopy was shown (date-only).
  static Future<DateTime?> loadLastResumeCopyDay() async {
    final p = await _sp();
    final s = p.getString(_kLastResumeCopyDay);
    if (s == null || s.trim().isEmpty) return null;
    return DateTime.tryParse(s);
  }

  // ─────────────────────────────────────────────
  // Reflections (user answers to evening prompts)
  // ─────────────────────────────────────────────

  static Future<void> saveReflection(
    String programId,
    int day,
    String answer,
  ) async {
    final p = await _sp();
    final key = 'reflection_${programId}_$day';
    await p.setString(key, answer.trim());
  }

  static Future<String?> loadReflection(String programId, int day) async {
    final p = await _sp();
    final key = 'reflection_${programId}_$day';
    return p.getString(key);
  }

  static Future<void> clearReflectionsForProgram(String programId) async {
    final p = await _sp();
    final keys = p.getKeys().where(
      (k) => k.startsWith('reflection_${programId}_'),
    );
    for (final key in keys) {
      await p.remove(key);
    }
  }

  // ─────────────────────────────────────────────
  // Clear (existing)
  // ─────────────────────────────────────────────

  static Future<void> clear() async {
    final p = await _sp();
    await p.remove(_kLang);

    // Mood (including window metadata)
    await clearMood();

    // Optional: keep active program or clear it — your choice
    // await p.remove(_kActiveProgramId);
  }
}
