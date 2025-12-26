import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/user_preferences_provider.dart';
import '../theme/aligna_theme.dart';
import '../utils/frequency_colors.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/reactive_aura_widget.dart';

class HomeSanctuaryScreen extends ConsumerWidget {
  const HomeSanctuaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = ref.watch(selectedFrequenciesProvider).maybeWhen(
      data: (value) => value,
      orElse: () => const <String>[],
    );
    final colors = frequencyColorsFromSelections(selections);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Home',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AlignaColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Settle in. Your sanctuary is ready.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AlignaColors.subtext,
                  ),
                ),
                const SizedBox(height: 24),
                ReactiveAuraWidget(
                  lumiImageUrl: 'assets/coach/aligna_coach.png',
                  programType: null,
                  programId: 'support',
                  restIntensity: 0.2,
                  overrideAuraColors:
                      colors.isNotEmpty ? colors : [AlignaColors.accent],
                  colorCycleDuration: const Duration(seconds: 14),
                ),
                const SizedBox(height: 16),
                if (selections.isNotEmpty)
                  Text(
                    'Active frequencies: ${selections.join(', ')}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AlignaColors.subtext,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
