import 'dart:ui';

import 'package:flutter/material.dart';

/// Aura state for the breathing glow effect
enum AuraState { idle, speaking, focus }

/// A pure Flutter widget that creates a breathing aura effect
/// using BackdropFilter blur and simple scale animation.
class AuraWidget extends StatefulWidget {
  final AuraState state;
  final Color color;

  const AuraWidget({super.key, required this.state, required this.color});

  @override
  State<AuraWidget> createState() => _AuraWidgetState();
}

class _AuraWidgetState extends State<AuraWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AuraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _applyState(widget.state);
    }
  }

  void _applyState(AuraState state) {
    switch (state) {
      case AuraState.idle:
        _controller.duration = const Duration(seconds: 7);
        break;
      case AuraState.speaking:
        _controller.duration = const Duration(seconds: 4);
        break;
      case AuraState.focus:
        _controller.duration = const Duration(milliseconds: 600);
        _controller.forward(from: 0.95);
        return;
    }
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
