import 'package:flutter/material.dart';
import '../theme/aligna_theme.dart';

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            color: AlignaColors.surface,
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AlignaColors.gold,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AlignaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AlignaColors.border),
            ),
            child: const _Dots(),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value; // 0..1
        int count = 1;
        if (t > 0.33) count = 2;
        if (t > 0.66) count = 3;
        final dots = '.' * count;

        return Text(
          'Typing$dots',
          style: const TextStyle(
            color: AlignaColors.subtext,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
