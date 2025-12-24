import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────
// Program engine (script-driven coach)
// ─────────────────────────────────────────────
import '../models/aligna_mood.dart' as prog;
import '../models/program_session.dart';
import '../providers/program_session_bundle_provider.dart';
import '../providers/program_progress_actions_provider.dart';
import '../providers/program_catalogue_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/resume_copy_provider.dart';

// ─────────────────────────────────────────────
// App-level state & providers
// ─────────────────────────────────────────────
import 'package:aligna_app/providers/app_providers.dart' as app;
import '../providers/coach_llm_provider.dart';
import '../providers/micro_action_provider.dart';

// ─────────────────────────────────────────────
// App infrastructure
// ─────────────────────────────────────────────
import '../l10n/l10n.dart';
import '../persistence/prefs.dart';

// ─────────────────────────────────────────────
// UI / theme / utilities
// ─────────────────────────────────────────────
import '../theme/aligna_theme.dart';
import '../utils/haptics.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/typing_bubble.dart';
import '../widgets/calm_cue.dart';
import '../widgets/program_picker_sheet.dart';

/// Single source of truth for active program id (prefs-backed).
final activeProgramIdProvider = FutureProvider<String?>((ref) async {
  return Prefs.loadActiveProgramId();
});

class CoachHomeScreen extends ConsumerStatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  ConsumerState<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends ConsumerState<CoachHomeScreen> {
  final TextEditingController _controller = TextEditingController();

  Timer? _expiryTimer;
  bool _expired = false;

  // Reflection controllers (key: 'programId_day')
  final Map<String, TextEditingController> _reflectionControllers = {};

  // Simple UI toggle (fully open mode: both available)
  ProgramTimeOfDay _timeOfDay = ProgramTimeOfDay.morning;

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _controller.dispose();
    for (final c in _reflectionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Map app mood (calm/stressed/tired/motivated) -> program mood
  prog.AlignaMood _mapMood(app.AlignaMood m) {
    switch (m) {
      case app.AlignaMood.stressed:
        return prog.AlignaMood.stressed;
      case app.AlignaMood.tired:
        return prog.AlignaMood.tiredBusy;
      case app.AlignaMood.motivated:
        return prog.AlignaMood.curious;
      case app.AlignaMood.calm:
        return prog.AlignaMood.fine;
    }
  }

  // v1: script asset path mapping (expand as you add scripts)
  String _scriptAssetPathFor(String programId) {
    if (programId == 'outcome_soothing_7d') {
      return 'assets/data/program_scripts/outcome_soothing_7d.v1.json';
    }
    return 'assets/data/program_scripts/outcome_soothing_7d.v1.json';
  }

  Future<void> _endSessionUiOnly() async {
    // UI-only cleanup. Do NOT clear mood. Do NOT pop navigation.
    ref.read(coachLlmProvider.notifier).clear();
    resetMicroActionFromWidget(ref);
    _controller.clear();

    _expiryTimer?.cancel();
    setState(() {
      _expired = false;
      ref.read(microActionStatusProvider.notifier).state =
          MicroActionStatus.offered;
    });
  }

  void _ensureReflectionLoaded(String programId, int day) async {
    final key = '${programId}_$day';
    if (_reflectionControllers.containsKey(key)) return;

    final previous = await Prefs.loadReflection(programId, day);
    if (!mounted) return;

    setState(() {
      _reflectionControllers[key] = TextEditingController(text: previous ?? '');
    });
  }

  Widget _buildReflectionField(String programId, int day) {
    final key = '${programId}_$day';
    final c = _reflectionControllers[key];
    if (c == null) {
      _ensureReflectionLoaded(programId, day);
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SizedBox(height: 18, child: LinearProgressIndicator()),
      );
    }

    return TextField(
      controller: c,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Your reflection...',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (value) async {
        await Prefs.saveReflection(programId, day, value);
      },
    );
  }

  Widget _buildProgramSession(
    BuildContext context,
    ProgramSessionBundle bundle,
    ProgramSessionRequest req,
  ) {
    final s = bundle.session;

    final resumeLine =
        bundle.plan.showResumeLine && req.timeOfDay == ProgramTimeOfDay.morning
        ? (bundle.plan.resumeTone == 'warm'
              ? s.resumeCopy.warm
              : s.resumeCopy.neutral)
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (resumeLine != null) ...[
            CoachBubble(text: resumeLine),
            const SizedBox(height: 12),
          ],
          for (final line in s.messages) ...[
            CoachBubble(text: line),
            const SizedBox(height: 10),
          ],
          if (s.microAction != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.microAction!.title.isEmpty
                          ? "One aligned step"
                          : s.microAction!.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(s.microAction!.instruction),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final actions = ref.read(
                          programProgressActionsProvider,
                        );
                        await actions.markCompleted(
                          current: bundle.progress,
                          completedDay: s.day,
                          durationDays: req.durationDays,
                        );
                        ref.invalidate(programSessionBundleProvider(req));
                      },
                      child: const Text("Start"),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Gentle: end the UI session only
                        await _endSessionUiOnly();
                      },
                      child: const Text("Not today"),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (s.reflection != null) ...[
            const SizedBox(height: 16),
            Text(
              s.reflection!.prompt,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (s.reflection!.exampleAnswers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Examples:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              for (final example in s.reflection!.exampleAnswers) ...[
                Text(
                  '• $example',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            _buildReflectionField(req.programId, s.day),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(ref);

    final appMood = ref.watch(app.moodProvider);
    final replyState = ref.watch(coachLlmProvider);

    final actionText = ref.watch(microActionTextProvider);
    final actionStatus = ref.watch(microActionStatusProvider);

    final progressAsync = ref.watch(programProgressProvider);
    final resumeAsync = ref.watch(resumeCopyProvider);

    final catalogueAsync = ref.watch(programCatalogueProvider);
    final activeProgramAsync = ref.watch(activeProgramIdProvider);

    // If mood is missing, show a calm recovery (do not pop routes).
    if (appMood == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.coachTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            CoachBubble(text: "Choose your mood to begin."),
            SizedBox(height: 10),
            CoachBubble(
              text:
                  "If you just opened the app, close it fully and reopen. Mood is selected at start.",
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.coachTitle),
        actions: [
          IconButton(
            tooltip: 'Programs',
            icon: const Icon(Icons.grid_view_outlined),
            onPressed: () async {
              final items = await ref.read(programCatalogueProvider.future);
              if (!context.mounted) return;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) {
                  return ProgramPickerSheet(
                    items: items,
                    isPro: true, // fully open mode; sheet should not upsell
                    onUpsellRequested: () {}, // no-op
                    onPick: (item) async {
                      await Prefs.setActiveProgramId(item.programId);
                      ref.invalidate(activeProgramIdProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting
          CoachBubble(text: t.moodLine(appMood)),
          const SizedBox(height: 10),

          // Resume microcopy (silent loading/error)
          resumeAsync.when(
            data: (res) {
              if (res.text == null) return const SizedBox.shrink();
              if (res.shouldMarkShown) {
                final markShown = ref.read(markResumeCopyShownProvider);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => markShown(),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Text(res.text!),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Day X of Y (silent loading/error)
          progressAsync.when(
            data: (progress) {
              if (progress == null) return const SizedBox.shrink();
              final text = progress.isComplete
                  ? 'Final day · ${progress.totalDays} of ${progress.totalDays}'
                  : 'Day ${progress.day} of ${progress.totalDays}';
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          // Active program state (single source of truth)
          activeProgramAsync.when(
            data: (activeId) {
              final isProgramMode = activeId != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isProgramMode
                              ? 'Program: $activeId'
                              : 'No program selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AlignaColors.subtext,
                          ),
                        ),
                      ),
                      if (isProgramMode) ...[
                        SegmentedButton<ProgramTimeOfDay>(
                          segments: const [
                            ButtonSegment(
                              value: ProgramTimeOfDay.morning,
                              label: Text('Morning'),
                            ),
                            ButtonSegment(
                              value: ProgramTimeOfDay.evening,
                              label: Text('Evening'),
                            ),
                          ],
                          selected: {_timeOfDay},
                          onSelectionChanged: (s) {
                            setState(() => _timeOfDay = s.first);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton(
                        onPressed: () async {
                          final items = await ref.read(
                            programCatalogueProvider.future,
                          );
                          if (!context.mounted) return;

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              return ProgramPickerSheet(
                                items: items,
                                isPro: true,
                                onUpsellRequested: () {},
                                onPick: (item) async {
                                  await Prefs.setActiveProgramId(
                                    item.programId,
                                  );
                                  ref.invalidate(activeProgramIdProvider);
                                  if (context.mounted) Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                        child: Text(isProgramMode ? 'Change' : 'Choose'),
                      ),
                      if (isProgramMode)
                        TextButton(
                          onPressed: () async {
                            await Prefs.clearActiveProgramId();
                            ref.invalidate(activeProgramIdProvider);
                          },
                          child: const Text('Stop'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Program-first: if program active, render program session.
                  if (isProgramMode)
                    _ProgramArea(
                      activeProgramId: activeId,
                      timeOfDay: _timeOfDay,
                      appMood: appMood,
                      catalogueAsync: catalogueAsync,
                      scriptAssetPathFor: _scriptAssetPathFor,
                      mapMood: _mapMood,
                      sessionBuilder: _buildProgramSession,
                    )
                  else
                    _ChatArea(
                      t: t,
                      controller: _controller,
                      replyState: replyState,
                      onSend: (text) {
                        ref.read(coachLlmProvider.notifier).generateReply(text);
                      },
                    ),

                  const SizedBox(height: 12),

                  // Micro-action system (kept, but should not fight program actions)
                  if (actionText != null &&
                      actionStatus == MicroActionStatus.offered)
                    _MicroActionCard(
                      text: actionText,
                      onStart: () {
                        ref.read(microActionStatusProvider.notifier).state =
                            MicroActionStatus.started;

                        _expiryTimer?.cancel();
                        _expired = false;

                        _expiryTimer = Timer(const Duration(seconds: 60), () {
                          if (!mounted) return;
                          setState(() => _expired = true);
                        });
                      },
                      onSkip: () {
                        ref.read(microActionStatusProvider.notifier).state =
                            MicroActionStatus.skipped;
                      },
                    ),

                  if (actionStatus == MicroActionStatus.started && !_expired)
                    _StartedActionBlock(onEnd: _endSessionUiOnly),

                  if (_expired) _ExpiredActionBlock(onEnd: _endSessionUiOnly),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Failed to load program state: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramArea extends ConsumerWidget {
  const _ProgramArea({
    required this.activeProgramId,
    required this.timeOfDay,
    required this.appMood,
    required this.catalogueAsync,
    required this.scriptAssetPathFor,
    required this.mapMood,
    required this.sessionBuilder,
  });

  final String activeProgramId;
  final ProgramTimeOfDay timeOfDay;
  final app.AlignaMood appMood;
  final AsyncValue<List<dynamic>> catalogueAsync;

  final String Function(String programId) scriptAssetPathFor;
  final prog.AlignaMood Function(app.AlignaMood) mapMood;

  final Widget Function(
    BuildContext context,
    ProgramSessionBundle bundle,
    ProgramSessionRequest req,
  )
  sessionBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = catalogueAsync.valueOrNull ?? const [];

    int durationDays = 7;
    for (final p in items) {
      // catalogue provider returns raw json maps (based on your usage)
      if (p is Map && p['programId'] == activeProgramId) {
        final d = p['durationDays'];
        if (d is int) durationDays = d;
        break;
      }
    }

    final req = ProgramSessionRequest(
      programId: activeProgramId,
      durationDays: durationDays,
      scriptAssetPath: scriptAssetPathFor(activeProgramId),
      timeOfDay: timeOfDay,
      mood: mapMood(appMood),
    );

    return ref
        .watch(programSessionBundleProvider(req))
        .when(
          data: (bundle) => sessionBuilder(context, bundle, req),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 16),
            child: TypingBubble(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Program load failed: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
  }
}

class _ChatArea extends StatelessWidget {
  const _ChatArea({
    required this.t,
    required this.controller,
    required this.replyState,
    required this.onSend,
  });

  final dynamic t;
  final TextEditingController controller;
  final AsyncValue replyState;
  final void Function(String text) onSend;

  @override
  Widget build(BuildContext context) {
    final hasReply = replyState.maybeWhen(
      data: (r) => r != null,
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CoachBubble(text: "What would you like to focus on today?"),
        const SizedBox(height: 12),

        if (!hasReply)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Your intention",
                    style: TextStyle(
                      fontSize: 13,
                      color: AlignaColors.subtext,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Keep it simple. One sentence is enough.",
                      hintStyle: const TextStyle(color: AlignaColors.subtext),
                      filled: true,
                      fillColor: const Color(0xFF0F1530),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AlignaColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      AppHaptics.light();
                      onSend(text);
                    },
                    child: const Text("Continue"),
                  ),
                ],
              ),
            ),
          ),

        replyState.when(
          data: (reply) {
            if (reply == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CoachBubble(text: reply.message),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 16),
            child: TypingBubble(),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Something went wrong. Try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _MicroActionCard extends StatelessWidget {
  const _MicroActionCard({
    required this.text,
    required this.onStart,
    required this.onSkip,
  });

  final String text;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "One aligned step",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(text),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onStart, child: const Text("Start")),
            TextButton(onPressed: onSkip, child: const Text("Not today")),
          ],
        ),
      ),
    );
  }
}

class _StartedActionBlock extends StatelessWidget {
  const _StartedActionBlock({required this.onEnd});
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          "Good. Just do the first 60 seconds. That counts.",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          "You can stop anytime.",
          style: TextStyle(color: AlignaColors.subtext),
        ),
        const SizedBox(height: 12),
        const CalmCue(visible: true, size: 120, isVeryTired: false),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onEnd, child: const Text("End session")),
      ],
    );
  }
}

class _ExpiredActionBlock extends StatelessWidget {
  const _ExpiredActionBlock({required this.onEnd});
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const CoachBubble(text: "That’s enough for today."),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onEnd, child: const Text("End session")),
      ],
    );
  }
}
