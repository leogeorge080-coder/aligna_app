import 'package:flutter/material.dart';

enum FrequencyMode { abundance, love, vitality, peace }

class FrequencyTheme {
  static String getAsset(FrequencyMode mode) {
    switch (mode) {
      case FrequencyMode.abundance:
        return 'assets/images/nebula_gold.webp';
      case FrequencyMode.love:
        return 'assets/images/nebula_pink.webp';
      case FrequencyMode.vitality:
        return 'assets/images/nebula_green.webp';
      case FrequencyMode.peace:
        return 'assets/images/nebula_blue.webp';
    }
  }

  static Color getAccent(FrequencyMode mode) {
    switch (mode) {
      case FrequencyMode.abundance:
        return const Color(0xFFFFD700);
      case FrequencyMode.love:
        return const Color(0xFFFF80AB);
      case FrequencyMode.vitality:
        return const Color(0xFF69F0AE);
      case FrequencyMode.peace:
        return const Color(0xFF40C4FF);
    }
  }
}
