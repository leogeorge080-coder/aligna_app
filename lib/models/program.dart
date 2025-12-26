import 'package:flutter/material.dart';

class Program {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? themeColor; // Hex color string like "#FFD700"
  final String track; // money/love/identity/health/purpose/support
  final int durationDays;
  final bool isActive;

  const Program({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.themeColor,
    required this.track,
    required this.durationDays,
    required this.isActive,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: (json['id'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      themeColor: json['theme_color'] as String?,
      track: (json['track'] as String?) ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 7,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Converts hex color string to Color, with fallback based on track
  Color getThemeColor() {
    if (themeColor != null && themeColor!.isNotEmpty) {
      try {
        // Remove # if present and parse
        final hex = themeColor!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        // Invalid hex, use fallback based on track
      }
    }

    // Fallback colors based on track
    switch (track) {
      case 'money':
      case 'wealth':
        return const Color(0xFFFFD700); // Gold for abundance/money
      case 'love':
        return const Color(0xFFFF69B4); // Hot pink for love
      case 'health':
        return const Color(0xFF32CD32); // Lime green for health
      case 'confidence':
      case 'identity':
        return const Color(0xFF9370DB); // Medium purple for confidence
      case 'purpose':
        return const Color(0xFFFF6347); // Tomato red for purpose
      case 'support':
        return const Color(0xFF4682B4); // Steel blue for support
      default:
        return const Color(0xFFE6F3FF); // Soft light blue fallback
    }
  }

  /// Gets secondary color for gradients (slightly darker/more muted version)
  Color getSecondaryColor() {
    final primary = getThemeColor();
    // Create a more muted secondary color
    final hsl = HSLColor.fromColor(primary);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  /// Gets aura colors as a list for compatibility with existing code
  List<Color> get auraColors => [getThemeColor(), getSecondaryColor()];
}
