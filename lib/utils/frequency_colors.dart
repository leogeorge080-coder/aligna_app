import 'package:flutter/material.dart';

const _frequencyColorMap = {
  'abundance': Color(0xFFFFD700),
  'innerpeace': Color(0xFF9370DB),
  'inner_peace': Color(0xFF9370DB),
  'love': Color(0xFFFFB6C1),
  'vitality': Color(0xFF00CED1),
  'health': Color(0xFF00CED1),
  'careergrowth': Color(0xFF00CED1),
  'career_growth': Color(0xFF00CED1),
};

List<Color> frequencyColorsFromSelections(List<String> selections) {
  final colors = <Color>[];
  for (final raw in selections) {
    final key = raw.toLowerCase().trim().replaceAll(' ', '');
    final mapped = _frequencyColorMap[key];
    if (mapped != null && !colors.contains(mapped)) {
      colors.add(mapped);
    }
  }
  return colors;
}
