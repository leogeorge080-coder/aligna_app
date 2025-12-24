import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AlignaLanguage { en, ar, hi, es }

enum AlignaMood { calm, stressed, tired, motivated }

final languageProvider = StateProvider<AlignaLanguage?>((ref) => null);
final moodProvider = StateProvider<AlignaMood?>((ref) => null);

final localeProvider = Provider<Locale>((ref) {
  final lang = ref.watch(languageProvider);
  return switch (lang) {
    AlignaLanguage.ar => const Locale('ar'),
    AlignaLanguage.hi => const Locale('hi'),
    AlignaLanguage.es => const Locale('es'),
    _ => const Locale('en'),
  };
});
