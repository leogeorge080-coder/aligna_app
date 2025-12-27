import 'dart:ui';

import 'package:flutter/material.dart';

class ShaderAuraOrb extends StatefulWidget {
  const ShaderAuraOrb({
    super.key,
    required this.primary,
    required this.secondary,
    this.intensity = 1.0,
    this.size = 320,
    this.child,
  });

  final Color primary;
  final Color secondary;
  final double intensity;
  final double size;
  final Widget? child;

  @override
  State<ShaderAuraOrb> createState() => _ShaderAuraOrbState();
}

class _ShaderAuraOrbState extends State<ShaderAuraOrb>
    with SingleTickerProviderStateMixin {
  FragmentProgram? _program;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      final program =
          await FragmentProgram.fromAsset('assets/shaders/breathing_orb.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _program = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ShaderOrbPainter(
              program: _program,
              time: _controller.value * 6.2831,
              intensity: widget.intensity,
              primary: widget.primary,
              secondary: widget.secondary,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _ShaderOrbPainter extends CustomPainter {
  _ShaderOrbPainter({
    required this.program,
    required this.time,
    required this.intensity,
    required this.primary,
    required this.secondary,
  });

  final FragmentProgram? program;
  final double time;
  final double intensity;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (program == null) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withOpacity(0.65),
            secondary.withOpacity(0.15),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size);
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2,
        paint,
      );
      return;
    }

    final shader = program!.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, intensity);
    shader.setFloat(4, primary.red / 255);
    shader.setFloat(5, primary.green / 255);
    shader.setFloat(6, primary.blue / 255);
    shader.setFloat(7, primary.opacity);
    shader.setFloat(8, secondary.red / 255);
    shader.setFloat(9, secondary.green / 255);
    shader.setFloat(10, secondary.blue / 255);
    shader.setFloat(11, secondary.opacity);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderOrbPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.intensity != intensity ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.program != program;
  }
}
