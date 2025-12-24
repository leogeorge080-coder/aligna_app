import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';
import '../theme/aligna_theme.dart';
import '../utils/haptics.dart';
import 'wiring_intro_screen.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key, this.source});

  /// Optional analytics context: e.g., 'daily_limit_sheet'
  final String? source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aligna Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Text(
            "Go a little deeper — gently",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            "Pro gives you a 21-day guided version of this — one short session a day around one steady intention.\n\nNo pressure. No streaks. You can skip days whenever you need.",
            style: TextStyle(height: 1.35),
          ),
          const SizedBox(height: 16),

          _FeatureCard(
            title: "21-day wiring program",
            body:
                "A calm daily structure: empathy → reframe → one micro-action → closure.",
          ),
          _FeatureCard(
            title: "One intention, revisited gently",
            body:
                "Less overwhelm. More direction. The same intention evolves over time.",
          ),
          _FeatureCard(
            title: "Mood-aware guidance",
            body:
                "Stressed/tired stays lighter. Motivated stays action-clear. Calm stays steady.",
          ),

          const SizedBox(height: 18),

          // Primary CTA
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AlignaColors.gold,
              foregroundColor: AlignaColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              // If user is already Pro, just go to wiring
              if (isPro) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const WiringIntroScreen()),
                );
                return;
              }

              // ✅ Purchase flow (TEMP: test mode)
              try {
                await AppHaptics.light();
              } catch (_) {}

              ref.read(isProProvider.notifier).state = true;

              if (!context.mounted) return;

              // Go straight into the 21-day program
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const WiringIntroScreen()),
              );
            },
            child: Text(
              isPro ? "Continue 21-day program" : "Start Pro",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary CTA
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Not now"),
          ),

          const SizedBox(height: 16),

          const Text(
            "Cancel anytime. No streak pressure. No magical promises.",
            style: TextStyle(color: AlignaColors.subtext),
          ),

          if (source != null) ...[
            const SizedBox(height: 10),
            Text(
              "Source: $source",
              style: const TextStyle(fontSize: 12, color: AlignaColors.subtext),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(height: 1.35)),
          ],
        ),
      ),
    );
  }
}
