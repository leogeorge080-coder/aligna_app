import 'dart:ui';

enum ProgramType {
  money,
  love,
  identity,
  health,
  purpose,
  support;

  String get displayName {
    switch (this) {
      case ProgramType.money:
        return 'Money & Wealth';
      case ProgramType.love:
        return 'Love & Healing';
      case ProgramType.identity:
        return 'Identity';
      case ProgramType.health:
        return 'Health & Vitality';
      case ProgramType.purpose:
        return 'Purpose';
      case ProgramType.support:
        return 'Support';
    }
  }

  // Aura colors based on program type
  List<Color> get auraColors {
    switch (this) {
      case ProgramType.money:
        return [const Color(0xFFFFD700), const Color(0xFF008080)]; // Gold, Teal
      case ProgramType.love:
        return [
          const Color(0xFFFFB6C1),
          const Color(0xFFE6E6FA),
        ]; // Rose, Lavender
      case ProgramType.health:
        return [
          const Color(0xFF98FB98),
          const Color(0xFF00FA9A),
        ]; // Mint, Spring Green
      case ProgramType.purpose:
        return [
          const Color(0xFFADD8E6),
          const Color(0xFFFFFFFF),
        ]; // Sky Blue, White
      case ProgramType.identity:
        return [
          const Color(0xFFFF69B4),
          const Color(0xFF9370DB),
        ]; // Hot Pink, Medium Purple
      case ProgramType.support:
        return [
          const Color(0xFF87CEEB),
          const Color(0xFF4682B4),
        ]; // Sky Blue, Steel Blue
    }
  }

  Color get uiAccent {
    switch (this) {
      case ProgramType.money:
        return const Color(0xFF008000); // Emerald
      case ProgramType.love:
        return const Color(0xFFFFC0CB); // Soft Pink
      case ProgramType.health:
        return const Color(0xFF006400); // Deep Green
      case ProgramType.purpose:
        return const Color(0xFF4B0082); // Indigo
      case ProgramType.identity:
        return const Color(0xFFFF1493); // Deep Pink
      case ProgramType.support:
        return const Color(0xFF4169E1); // Royal Blue
    }
  }

  static ProgramType fromString(String track) {
    switch (track.toLowerCase()) {
      case 'money':
        return ProgramType.money;
      case 'love':
        return ProgramType.love;
      case 'identity':
        return ProgramType.identity;
      case 'health':
        return ProgramType.health;
      case 'purpose':
        return ProgramType.purpose;
      case 'support':
      default:
        return ProgramType.support;
    }
  }
}
