import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlignaColors {
  // Sanctuary Background Gradient
  static const deepIndigo = Color(0xFF1A1B41);
  static const softPurple = Color(0xFF7678ED);

  // Action Buttons
  static const radiantGold = Color(0xFFFFD700);
  static const sunsetCoral = Color(0xFFFF8C61);

  // Journal (Frosted Glass)
  static const frostedWhite = Color(0x1AFFFFFF); // White with 10% opacity

  // Coach's Glow
  static const etherealMint = Color(0xFFD1FFD7);

  // Legacy colors for compatibility
  static const bg = deepIndigo;
  static const surface = Color(0xFF141A33);
  static const border = Color(0xFF1E254A);
  static const text = Color(0xFFF5F6FA);
  static const subtext = Color(0xFFB6B9C6);
  static const gold = radiantGold;

  // Additional colors for UI
  static const primary = softPurple;
  static const accent = radiantGold;
}

ThemeData buildAlignaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: AlignaColors.surface,
      primary: AlignaColors.radiantGold,
      secondary: AlignaColors.sunsetCoral,
    ),
    scaffoldBackgroundColor: AlignaColors.deepIndigo,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white.withOpacity(0.1),
      foregroundColor: AlignaColors.text,
      elevation: 0,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        side: BorderSide(
          color: Color(0x33FFFFFF), // 20% white
          width: 1,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
    ),
    textTheme:
        GoogleFonts.montserratTextTheme(
          base.textTheme.apply(
            bodyColor: AlignaColors.text,
            displayColor: AlignaColors.text,
          ),
        ).copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AlignaColors.text,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AlignaColors.text,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AlignaColors.text,
          ),
          bodyLarge: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AlignaColors.text,
          ),
          bodyMedium: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AlignaColors.text,
          ),
          labelLarge: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AlignaColors.text,
          ),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AlignaColors.frostedWhite,
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 2,
          color: AlignaColors.radiantGold.withOpacity(0.3),
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(width: 2, color: AlignaColors.radiantGold),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 2,
          color: AlignaColors.radiantGold.withOpacity(0.3),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AlignaColors.radiantGold,
        foregroundColor: AlignaColors.deepIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: AlignaColors.text,
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      ),
    ),
  );
}
