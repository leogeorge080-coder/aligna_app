import 'package:flutter/material.dart';

enum SanctuaryState { sunrise, daylight, twilight }

class SanctuaryThemeData {
  final SanctuaryState state;
  final Color primary;
  final Color secondary;
  final String tone;

  const SanctuaryThemeData({
    required this.state,
    required this.primary,
    required this.secondary,
    required this.tone,
  });

  LinearGradient gradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary],
    );
  }

  Color get adaptiveTextColor {
    if (state == SanctuaryState.daylight) {
      return const Color(0xFF1A1A2E);
    }
    return Colors.white;
  }
}

SanctuaryState resolveSanctuaryState(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 10) return SanctuaryState.sunrise;
  if (hour >= 10 && hour < 18) return SanctuaryState.daylight;
  return SanctuaryState.twilight;
}

SanctuaryThemeData themeForState(SanctuaryState state) {
  switch (state) {
    case SanctuaryState.sunrise:
      return const SanctuaryThemeData(
        state: SanctuaryState.sunrise,
        primary: Color(0xFFFF9D6C),
        secondary: Color(0xFFFDCB6E),
        tone: 'soft',
      );
    case SanctuaryState.daylight:
      return const SanctuaryThemeData(
        state: SanctuaryState.daylight,
        primary: Color(0xFF48CAE4),
        secondary: Color(0xFFFFFFFF),
        tone: 'bright',
      );
    case SanctuaryState.twilight:
      return const SanctuaryThemeData(
        state: SanctuaryState.twilight,
        primary: Color(0xFF1A1A2E),
        secondary: Color(0xFF4831D4),
        tone: 'calm',
      );
  }
}
