import 'package:flutter/material.dart';

class AlignaColors {
  static const bg = Color(0xFF0B1020);
  static const surface = Color(0xFF141A33);
  static const border = Color(0xFF1E254A);
  static const text = Color(0xFFF5F6FA);
  static const subtext = Color(0xFFB6B9C6);
  static const gold = Color(0xFFD6C28E);
}

ThemeData buildAlignaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: AlignaColors.surface,
      primary: AlignaColors.gold,
    ),
    scaffoldBackgroundColor: AlignaColors.bg,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AlignaColors.bg,
      foregroundColor: AlignaColors.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AlignaColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AlignaColors.border, width: 1),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AlignaColors.text,
      displayColor: AlignaColors.text,
    ),
  );
}
