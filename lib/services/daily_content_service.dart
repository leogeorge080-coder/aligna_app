import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_content.dart';

class DailyContentService {
  static final supabase = Supabase.instance.client;

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

      return (response as List)
          .map((json) => DailyContent.fromJson(json))
          .toList();
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

      return (response as List)
          .map((json) => DailyContent.fromJson(json))
          .toList();
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
