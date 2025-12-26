import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aligna_app/models/program_type.dart';

enum AlignaLanguage { en, ar, hi, es, fr, ta, ml }

enum AlignaMood { calm, stressed, tired, motivated }

enum HeartMood { low, high }

final languageProvider = StateProvider<String?>((ref) => null);
final userNameProvider = StateProvider<String?>((ref) => null);
final moodProvider = StateProvider<AlignaMood?>((ref) => null);
final heartMoodProvider = StateProvider<HeartMood?>((ref) => null);
final activeProgramIdProvider = StateProvider<String?>((ref) => null);
final selectedProgramTypeProvider = StateProvider<ProgramType?>((ref) => null);
final startingStateProvider = StateProvider<String?>((ref) => null);
final timePreferenceProvider = StateProvider<int>(
  (ref) => 5,
); // Default to 5 minutes
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);
final shellTabIndexProvider = StateProvider<int>(
  (ref) => 0,
); // 0 Coach, 1 Programs, 2 Settings

final localeProvider = Provider<Locale>((ref) {
  final lang = ref.watch(languageProvider);
  return switch (lang) {
    'ar' => const Locale('ar'),
    'hi' => const Locale('hi'),
    'es' => const Locale('es'),
    'fr' => const Locale('fr'),
    'ta' => const Locale('ta'),
    'ml' => const Locale('ml'),
    _ => const Locale('en'),
  };
});
