import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/program.dart';
import '../services/program_service.dart';

/// Provider for fetching a program by ID
final programProvider = FutureProvider.family<Program?, String>((
  ref,
  programId,
) async {
  return ProgramService.getProgramObjectById(programId);
});

/// Provider for fetching a program by slug
final programBySlugProvider = FutureProvider.family<Program?, String>((
  ref,
  slug,
) async {
  return ProgramService.getProgramBySlug(slug);
});

/// Provider for fetching all programs
final allProgramsProvider = FutureProvider<List<Program>>((ref) async {
  return ProgramService.getAllPrograms();
});

/// Provider for fetching program theme color by ID
final programThemeColorProvider = FutureProvider.family<Color?, String>((
  ref,
  programId,
) async {
  final program = await ProgramService.getProgramObjectById(programId);
  return program?.getThemeColor();
});

/// Provider for fetching program aura colors by ID (for compatibility)
final programAuraColorsProvider = FutureProvider.family<List<Color>?, String>((
  ref,
  programId,
) async {
  final program = await ProgramService.getProgramObjectById(programId);
  return program?.auraColors ??
      [const Color(0xFFE6F3FF), const Color(0xFFB3D9FF)]; // Fallback colors
});

/// Provider for fetching available languages from daily_content table
final availableLanguagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    if (kDebugMode) {
      debugPrint(
        '[AvailableLanguagesProvider] Querying daily_content for language codes...',
      );
    }

    final response = await Supabase.instance.client
        .from('daily_content')
        .select('language_code')
        .order('language_code');

    if (kDebugMode) {
      debugPrint('[AvailableLanguagesProvider] Raw response: $response');
      debugPrint(
        '[AvailableLanguagesProvider] Response type: ${response.runtimeType}',
      );
      debugPrint(
        '[AvailableLanguagesProvider] Response length: ${(response as List?)?.length ?? 'null'}',
      );
    }

    // Get unique language codes
    final Set<String> languageCodes = {};
    for (final row in response) {
      final code = row['language_code'] as String?;
      if (code != null) {
        languageCodes.add(code);
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[AvailableLanguagesProvider] Unique language codes: $languageCodes',
      );
    }

    return languageCodes.toList();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[AvailableLanguagesProvider] Error fetching languages: $e');
    }
    // Fallback to supported languages if query fails
    return ['en', 'hi', 'ar', 'es'];
  }
});
