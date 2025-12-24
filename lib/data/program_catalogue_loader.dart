import 'dart:convert';
import 'package:flutter/services.dart';

class ProgramCatalogueLoader {
  static Future<List<Map<String, dynamic>>> load() async {
    final raw = await rootBundle.loadString(
      'assets/data/program_catalogue.json',
    );
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(decoded['programs']);
  }
}
