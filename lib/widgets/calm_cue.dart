import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/breathing_aura.dart';

import '../providers/app_providers.dart';

/// Policy for whether/how to show calming visuals.
class CalmCuePolicy {
  final bool enabled;
  final double intensity; // 0.0–1.2 (keep <= 1.0 in Aligna)
  final int cycleSeconds; // breathing cycle duration
  final bool showAura; // whether to include glow
  const CalmCuePolicy({
    required this.enabled,
    required this.intensity,
    required this.cycleSeconds,
    required this.showAura,
  });
}

/// Centralised decision logic (so you don’t sprinkle conditions everywhere).
CalmCuePolicy calmCuePolicyForMood({
  required AlignaMood mood,
  required bool isVeryTired, // your app can compute this later
}) {
  // When NOT to show:
  // - Very tired: avoid any extra stimulation; keep it purely text + exit control.
  if (isVeryTired) {
    return const CalmCuePolicy(
      enabled: false,
      intensity: 0.0,
      cycleSeconds: 7,
      showAura: false,
    );
  }

  switch (mood) {
    case AlignaMood.stressed:
      return const CalmCuePolicy(
        enabled: true,
        intensity: 0.55,
        cycleSeconds: 8, // slower for regulation
        showAura: true,
      );
    case AlignaMood.tired:
      return const CalmCuePolicy(
        enabled: true,
        intensity: 0.60,
        cycleSeconds: 8,
        showAura: false, // less stimulation
      );
    case AlignaMood.calm:
      return const CalmCuePolicy(
        enabled: true,
        intensity: 0.90,
        cycleSeconds: 7,
        showAura: true,
      );
    case AlignaMood.motivated:
      return const CalmCuePolicy(
        enabled: true,
        intensity: 1.0,
        cycleSeconds: 6, // slightly faster
        showAura: true,
      );
  }
}

/// A small wrapper widget that applies policy + safe mounting.
/// Use it anywhere you want a calming cue.
class CalmCue extends ConsumerWidget {
  const CalmCue({
    super.key,
    required this.visible,
    this.size = 120,
    this.isVeryTired = false,
  });

  final bool visible;
  final double size;
  final bool isVeryTired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);

    // If mood is missing, do not show cues.
    if (mood == null) return const SizedBox.shrink();

    final policy = calmCuePolicyForMood(mood: mood, isVeryTired: isVeryTired);

    final show = visible && policy.enabled;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: show
          ? Center(
              child: BreathingAura(
                key: const ValueKey('breathing-aura'),
                size: size,
                cycleSeconds: policy.cycleSeconds,
                intensity: policy.intensity,
                showAura: policy.showAura,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
