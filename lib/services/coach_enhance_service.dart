import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CoachEnhanceRequest {
  final String programId;
  final int day;
  final String blockId;
  final String moodKey; // "fine" | "stressed" | "tired" | "curious" etc.
  final String language; // "en" | "ar" | "hi" | "es"
  final List<String> fallbackLines;
  final int maxLines;

  const CoachEnhanceRequest({
    required this.programId,
    required this.day,
    required this.blockId,
    required this.moodKey,
    required this.language,
    required this.fallbackLines,
    this.maxLines = 3,
  });

  Map<String, dynamic> toJson() => {
    "programId": programId,
    "day": day,
    "blockId": blockId,
    "moodKey": moodKey,
    "language": language,
    "fallbackLines": fallbackLines,
    "maxLines": maxLines,
  };
}

class CoachEnhanceResult {
  final List<String> lines;
  final String? source; // "llm" | "fallback" (if you return it)

  const CoachEnhanceResult({required this.lines, this.source});

  factory CoachEnhanceResult.fromJson(Map<String, dynamic> json) {
    final raw = json["lines"];
    if (raw is! List) {
      throw const FormatException('Invalid response: "lines" missing');
    }
    final lines = raw.map((e) => e.toString()).toList();
    return CoachEnhanceResult(lines: lines, source: json["source"]?.toString());
  }
}

class CoachEnhanceService {
  CoachEnhanceService({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String supabaseUrl; // e.g. https://xxxx.supabase.co
  final String supabaseAnonKey; // your anon public key (JWT-looking)
  final http.Client _client;

  Uri get _endpoint =>
      Uri.parse('$supabaseUrl/functions/v1/aligna-coach-enhance');

  Future<CoachEnhanceResult> enhance({
    required CoachEnhanceRequest request,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final res = await _client
        .post(
          _endpoint,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $supabaseAnonKey",
            "apikey": supabaseAnonKey,
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Try to surface server detail for debugging
      String detail = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded["detail"] != null) {
          detail = decoded["detail"].toString();
        }
      } catch (_) {}
      throw HttpException(
        'Enhance failed (${res.statusCode}): $detail',
        uri: _endpoint,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Enhance response must be a JSON object.');
    }
    return CoachEnhanceResult.fromJson(decoded);
  }
}
