import 'package:flutter/material.dart';

/// A small glowing aura orb widget for program selection
class AuraOrb extends StatelessWidget {
  final List<Color> colors;
  final double size;

  const AuraOrb({super.key, required this.colors, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors[0].withValues(alpha: 0.8),
            colors[0].withValues(alpha: 0.4),
            colors[1].withValues(alpha: 0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.6),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.6,
          height: size * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[0].withValues(alpha: 0.3),
            border: Border.all(
              color: colors[0].withValues(alpha: 0.8),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
