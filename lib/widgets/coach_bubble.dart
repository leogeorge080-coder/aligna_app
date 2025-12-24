import 'package:flutter/material.dart';
import '../theme/aligna_theme.dart';

class CoachBubble extends StatelessWidget {
  const CoachBubble({super.key, required this.text});

  final String text;

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
            child: Image.asset(
              'assets/coach/aligna_coach.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.auto_awesome, color: AlignaColors.gold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AlignaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AlignaColors.border),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}
