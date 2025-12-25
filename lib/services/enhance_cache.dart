import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EnhanceCache {
  static Future<List<String>?> getLines(String key) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(key);
    if (raw == null) return null;
    final decoded = json.decode(raw);
    if (decoded is! List) return null;
    return decoded.whereType<String>().toList();
  }

  static Future<void> setLines(String key, List<String> lines) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, json.encode(lines));
  }
}
