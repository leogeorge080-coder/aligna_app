import 'package:flutter/material.dart';

/// A Lumi Glow Orb widget with different pulsing behaviors
class LumiGlowOrb extends StatefulWidget {
  final String glowType;
  final Color color;
  final double size;

  const LumiGlowOrb({
    super.key,
    required this.glowType,
    required this.color,
    this.size = 32,
  });

  @override
  State<LumiGlowOrb> createState() => _LumiGlowOrbState();
}

class _LumiGlowOrbState extends State<LumiGlowOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Configure animation based on glow type
    switch (widget.glowType) {
      case 'fast_jagged':
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        )..repeat(reverse: true);
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        break;

      case 'slow_dimming':
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 3000),
          vsync: this,
        )..repeat(reverse: true);
        _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        _opacityAnimation = Tween<double>(begin: 0.3, end: 0.1).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        break;

      case 'light_fast_pulsing':
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: this,
        )..repeat(reverse: true);
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        break;

      case 'slow_deep_breathing':
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 4000),
          vsync: this,
        )..repeat(reverse: true);
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        _opacityAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        break;

      case 'bright_expansive':
      default:
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 2000),
          vsync: this,
        )..repeat(reverse: true);
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
      builder: (context, child) {
        return Container(
          width: widget.size * _scaleAnimation.value,
          height: widget.size * _scaleAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: _opacityAnimation.value),
                widget.color.withValues(alpha: _opacityAnimation.value * 0.6),
                widget.color.withValues(alpha: _opacityAnimation.value * 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: _opacityAnimation.value * 0.8,
                ),
                blurRadius: widget.size * 0.8 * _scaleAnimation.value,
                spreadRadius: widget.size * 0.2 * _scaleAnimation.value,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.4),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.9),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
