import 'dart:math';

import 'package:flutter/material.dart';

class LiquidProgressOrb extends StatefulWidget {
  const LiquidProgressOrb({
    super.key,
    required this.progress,
    required this.primary,
    required this.secondary,
    this.size = 180,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final double size;

  @override
  State<LiquidProgressOrb> createState() => _LiquidProgressOrbState();
}

class _LiquidProgressOrbState extends State<LiquidProgressOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LiquidOrbPainter(
            progress: widget.progress,
            primary: widget.primary,
            secondary: widget.secondary,
            phase: _controller.value * 2 * pi,
          ),
        );
      },
    );
  }
}

class _LiquidOrbPainter extends CustomPainter {
  _LiquidOrbPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.phase,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Offset.zero & size;
    final clipPath = Path()..addOval(rect);

    canvas.save();
    canvas.clipPath(clipPath);

    final fillHeight = size.height * (1 - progress.clamp(0.0, 1.0));
    final waveHeight = size.height * 0.03;
    final waveLength = size.width * 1.2;

    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final y = fillHeight +
          sin((x / waveLength * 2 * pi) + phase) * waveHeight;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primary.withOpacity(0.85),
        secondary.withOpacity(0.6),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawPath(path, paint);

    canvas.restore();

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = primary.withOpacity(0.7);
    canvas.drawCircle(center, radius - 1, outline);
  }

  @override
  bool shouldRepaint(covariant _LiquidOrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.phase != phase;
  }
}
