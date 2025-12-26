import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_content.dart';

class DailyContentService {
  static final supabase = Supabase.instance.client;

  static Future<String?> _signedAudioUrl(String? raw) async {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    try {
      return await supabase.storage
          .from('audio_sessions')
          .createSignedUrl(value, 600);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[DailyContentService] Failed to sign audio URL: $e');
        debugPrintStack(stackTrace: st);
      }
      return null;
    }
  }

  /// Fetches daily content for a specific program, day and language
  static Future<DailyContent?> fetchDayContent({
    required String programId,
    required int dayNumber,
    required String languageCode,
  }) async {
    // DEBUG: Log query parameters
    if (kDebugMode) {
      debugPrint('[DailyContentService] Querying with:');
      debugPrint('  program_id: $programId');
      debugPrint('  day_number: $dayNumber');
      debugPrint('  language_code: $languageCode');
    }

    try {
      final response = await supabase
          .from('daily_content')
          .select('*')
          .eq('program_id', programId)
          .eq('day_number', dayNumber)
          .eq('language_code', languageCode)
          .single();

      // DEBUG: Log the response
      if (kDebugMode) {
        debugPrint('[DailyContentService] Response received:');
        debugPrint('  audio_url: ${response['audio_url']}');
        debugPrint('  title: ${response['title']}');
      }

      final signed = await _signedAudioUrl(response['audio_url'] as String?);
      if (signed != null) {
        response['audio_url'] = signed;
      }

      return DailyContent.fromJson(response);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[DailyContentService] Failed to fetch day $dayNumber for program $programId and language $languageCode',
        );
        debugPrint('$e');
        debugPrintStack(stackTrace: st);
      }
      return null;
    }
  }

  /// Fetches all daily content for a specific program and language (useful for caching)
  static Future<List<DailyContent>> fetchAllContentForProgram(
    String programId,
    String languageCode,
  ) async {
    try {
      final response = await supabase
          .from('daily_content')
          .select('*')
          .eq('program_id', programId)
          .eq('language_code', languageCode)
          .order('day_number');

      final items = <DailyContent>[];
      for (final raw in (response as List)) {
        final json = Map<String, dynamic>.from(raw as Map);
        final signed = await _signedAudioUrl(json['audio_url'] as String?);
        if (signed != null) {
          json['audio_url'] = signed;
        }
        items.add(DailyContent.fromJson(json));
      }
      return items;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[DailyContentService] Failed to fetch all content for program $programId and language $languageCode',
        );
        debugPrint('$e');
        debugPrintStack(stackTrace: st);
      }
      return [];
    }
  }

  /// Fetches content for a range of days in a specific program and language
  static Future<List<DailyContent>> fetchContentRange({
    required String programId,
    required int startDay,
    required int endDay,
    required String languageCode,
  }) async {
    try {
      final response = await supabase
          .from('daily_content')
          .select('*')
          .eq('program_id', programId)
          .eq('language_code', languageCode)
          .gte('day_number', startDay)
          .lte('day_number', endDay)
          .order('day_number');

      final items = <DailyContent>[];
      for (final raw in (response as List)) {
        final json = Map<String, dynamic>.from(raw as Map);
        final signed = await _signedAudioUrl(json['audio_url'] as String?);
        if (signed != null) {
          json['audio_url'] = signed;
        }
        items.add(DailyContent.fromJson(json));
      }
      return items;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[DailyContentService] Failed to fetch content range $startDay-$endDay for program $programId and language $languageCode',
        );
        debugPrint('$e');
        debugPrintStack(stackTrace: st);
      }
      return [];
    }
  }
}
