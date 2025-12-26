import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/daily_content.dart';
import '../services/daily_content_service.dart';
import '../services/program_service.dart';
import 'app_providers.dart';

/// Provider for fetching daily content for the current day, program and language
final dailyContentProvider = FutureProvider.family<DailyContent?, String>((
  ref,
  programIdOrSlug,
) async {
  final languageCode = ref.watch(languageProvider) ?? 'en';

  // For now, use day 1 as default. In a real app, this would be based on
  // user's progress or current date
  const currentDay = 1;

  // First try to get the UUID from the slug, if it fails, assume programIdOrSlug is already a UUID
  String programId = programIdOrSlug;
  try {
    final uuid = await ProgramService.getProgramIdBySlug(programIdOrSlug);
    if (uuid != null) {
      programId = uuid;
    }
  } catch (e) {
    // If slug lookup fails, assume programIdOrSlug is already a UUID
    // This handles both cases: slug-based lookups and direct UUID usage
  }

  if (kDebugMode) {
    debugPrint('[DailyContentProvider] About to query daily_content:');
    debugPrint('  program_id: $programId (from input: $programIdOrSlug)');
    debugPrint('  day_number: $currentDay');
    debugPrint('  language_code: $languageCode');
  }

  return DailyContentService.fetchDayContent(
    programId: programId,
    dayNumber: currentDay,
    languageCode: languageCode,
  );
});

/// Provider for fetching all daily content for a specific program and language (for caching)
final allDailyContentForProgramProvider =
    FutureProvider.family<List<DailyContent>, String>((
      ref,
      programIdOrSlug,
    ) async {
      final languageCode = ref.watch(languageProvider) ?? 'en';

      // Resolve slug to UUID if needed
      String programId = programIdOrSlug;
      try {
        final uuid = await ProgramService.getProgramIdBySlug(programIdOrSlug);
        if (uuid != null) {
          programId = uuid;
        }
      } catch (e) {
        // If slug lookup fails, assume programIdOrSlug is already a UUID
      }

      return DailyContentService.fetchAllContentForProgram(
        programId,
        languageCode,
      );
    });

/// Provider for fetching daily content for a specific program and day
final dailyContentForProgramDayProvider =
    FutureProvider.family<DailyContent?, ({String programId, int dayNumber})>((
      ref,
      params,
    ) async {
      final languageCode = ref.watch(languageProvider) ?? 'en';

      // Resolve slug to UUID if needed
      String programId = params.programId;
      try {
        final uuid = await ProgramService.getProgramIdBySlug(params.programId);
        if (uuid != null) {
          programId = uuid;
        }
      } catch (e) {
        // If slug lookup fails, assume params.programId is already a UUID
      }

      return DailyContentService.fetchDayContent(
        programId: programId,
        dayNumber: params.dayNumber,
        languageCode: languageCode,
      );
    });
