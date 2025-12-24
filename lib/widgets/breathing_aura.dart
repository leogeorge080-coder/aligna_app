import 'package:flutter/material.dart';

class BreathingAura extends StatefulWidget {
  const BreathingAura({
    super.key,
    this.size = 120,
    this.cycleSeconds = 7,
    this.intensity = 1.0,
    this.showAura = true,
  });

  final double size;
  final int cycleSeconds;
  final double intensity;
  final bool showAura;

  @override
  State<BreathingAura> createState() => _BreathingAuraState();
}

class _BreathingAuraState extends State<BreathingAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.cycleSeconds),
    )..repeat(reverse: true);

    _t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant BreathingAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleSeconds != widget.cycleSeconds) {
      _c.duration = Duration(seconds: widget.cycleSeconds);
      _c
        ..stop()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final intensity = widget.intensity.clamp(0.3, 1.2);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          final v = _t.value;

          final coreScale = _lerp(0.92, 1.02, v);
          final ringScale = _lerp(0.92, 1.12, v);
          final auraScale = _lerp(0.95, 1.08, v);

          final ringOpacity = _lerp(0.14, 0.28, v) * intensity;
          final auraOpacity = _lerp(0.10, 0.22, v) * intensity;

          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showAura)
                Transform.scale(
                  scale: auraScale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: auraOpacity),
                          blurRadius: 28,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

              Opacity(
                opacity: ringOpacity,
                child: Transform.scale(
                  scale: ringScale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primary.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              Transform.scale(
                scale: coreScale,
                child: Container(
                  width: widget.size * 0.22,
                  height: widget.size * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
