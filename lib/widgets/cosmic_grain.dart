import 'dart:math';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

class CosmicGrain extends StatelessWidget {
  const CosmicGrain({super.key, this.opacity = 0.05});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: const _GrainPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.0;
    final random = Random();
    final points = <Offset>[];
    final density = (size.width * size.height) * 0.002;

    for (var i = 0; i < density; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      if (random.nextDouble() > 0.8) {
        points.add(Offset(x, y));
      }
    }

    paint.color = Colors.white;
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
