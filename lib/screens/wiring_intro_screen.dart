import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wiring_providers.dart';
import '../providers/wiring_llm_provider.dart';

class WiringIntroScreen extends ConsumerStatefulWidget {
  const WiringIntroScreen({super.key});

  @override
  ConsumerState<WiringIntroScreen> createState() => _WiringIntroScreenState();
}

class _WiringIntroScreenState extends ConsumerState<WiringIntroScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(wiringControllerProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(wiringDayProvider) ?? 1;
    final canComplete = ref.watch(wiringCanCompleteTodayProvider);
    final core = ref.watch(wiringCoreIntentionProvider);

    // ─────────────────────────────────────────────
    // Core intention gate
    // ─────────────────────────────────────────────
    if (core == null || core.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('21-day program')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Let’s set your intention first",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                "This program works best when we keep one steady intention.",
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const WiringIntroScreen(),
                    ),
                  );
                },
                child: const Text("Set intention"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Not now"),
              ),
            ],
          ),
        ),
      );
    }

    // ─────────────────────────────────────────────
    // LLM reply
    // ─────────────────────────────────────────────
    final replyAsync = ref.watch(wiringLlmReplyProvider);

    return replyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Day $day of 21')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text('Day $day of 21')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "We couldn’t load today’s guidance",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                "Check your connection and try again.",
                style: TextStyle(color: Color(0xFFB6B9C6)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(wiringLlmReplyProvider),
                child: const Text("Retry"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Not today"),
              ),
            ],
          ),
        ),
      ),
      data: (reply) {
        final focus = reply.message.trim();
        final step = (reply.microAction ?? '').trim();
        final closure = (reply.closure ?? '').trim();

        return Scaffold(
          appBar: AppBar(title: Text('Day $day of 21')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Day $day',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(core, style: const TextStyle(color: Color(0xFFB6B9C6))),
              const SizedBox(height: 12),

              _CardBlock(title: "Today’s focus", body: focus),
              _CardBlock(
                title: "One aligned step",
                body: step.isEmpty
                    ? "Choose one tiny step you can do in 2 minutes."
                    : step,
              ),

              if (closure.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(closure, style: const TextStyle(color: Color(0xFFB6B9C6))),
              ],

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: canComplete
                    ? () async {
                        final nav = Navigator.of(context);
                        await ref
                            .read(wiringControllerProvider)
                            .markDoneToday();
                        if (!mounted) return;
                        nav.pop();
                      }
                    : null,
                child: Text(canComplete ? 'Mark done' : 'Done for today'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not today'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.title, required this.body});

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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
