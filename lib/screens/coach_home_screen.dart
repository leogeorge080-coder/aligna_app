// lib/screens/coach_home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────
// Program engine (script-driven coach)
// ─────────────────────────────────────────────
import '../models/program_session.dart';
import '../providers/program_session_bundle_provider.dart';
import '../providers/program_progress_actions_provider.dart';
import '../providers/program_catalogue_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/resume_copy_provider.dart';
import '../models/program_progress.dart';
import '../models/program_resume_plan.dart';

// ─────────────────────────────────────────────
// App-level state & providers
// ─────────────────────────────────────────────
import 'package:aligna_app/providers/app_providers.dart' as app;
import '../providers/coach_llm_provider.dart';
import '../providers/micro_action_provider.dart';
import '../providers/coach_enhance_providers.dart';
import '../services/coach_enhance_service.dart';

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
import '../widgets/aura_widget.dart';
import '../widgets/staggered_coach_bubbles.dart';

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
  final ProgramTimeOfDay _timeOfDay = ProgramTimeOfDay.morning;

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
  String _mapMood(app.AlignaMood m) {
    switch (m) {
      case app.AlignaMood.stressed:
        return 'stressed';
      case app.AlignaMood.tired:
        return 'tired';
      case app.AlignaMood.motivated:
        return 'motivated';
      case app.AlignaMood.calm:
        return 'calm';
    }
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
          StaggeredCoachBubbles(messages: s.messages),
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

  // Robust extractors for both Map-based and typed catalogue models
  String? _catalogueProgramId(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      final v = item['programId'];
      return v is String && v.trim().isNotEmpty ? v : null;
    }
    try {
      final v = (item as dynamic).programId;
      return v is String && v.trim().isNotEmpty ? v : null;
    } catch (_) {
      return null;
    }
  }

  int? _catalogueDurationDays(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      final v = item['durationDays'];
      return v is int ? v : int.tryParse('$v');
    }
    try {
      final v = (item as dynamic).durationDays;
      return v is int ? v : int.tryParse('$v');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(ref);

    final appMood = ref.watch(app.moodProvider);
    final replyState = ref.watch(coachLlmProvider);

    final actionText = ref.watch(microActionTextProvider);
    final actionStatus = ref.watch(microActionStatusProvider);

    final catalogueAsync = ref.watch(programCatalogueProvider);

    // IMPORTANT: treat empty string as null (common prefs bug source)
    final rawActiveId = ref.watch(app.activeProgramIdProvider);
    final activeId = (rawActiveId == null || rawActiveId.trim().isEmpty)
        ? null
        : rawActiveId;

    final progressAsync = activeId == null
        ? const AsyncValue.data(null)
        : ref.watch(programProgressProvider);

    final resumeAsync = activeId == null
        ? const AsyncValue.data(
            ResumeCopyResult(text: null, shouldMarkShown: false),
          )
        : ref.watch(resumeCopyProvider);

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
                    isPro: false,
                    onUpsellRequested: () {},
                    onPick: (item) async {
                      final pid = _catalogueProgramId(item);
                      if (pid == null) {
                        debugPrint('[PROGRAM] pick failed: null programId');
                        return;
                      }
                      await Prefs.setActiveProgramId(pid);
                      ref.read(app.activeProgramIdProvider.notifier).state =
                          pid;
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
          Builder(
            builder: (context) {
              final isProgramMode = activeId != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isProgramMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Program active',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () =>
                              ref
                                      .read(app.shellTabIndexProvider.notifier)
                                      .state =
                                  1,
                          child: const Text('Change'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'No program selected',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AlignaColors.subtext,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref
                                      .read(app.shellTabIndexProvider.notifier)
                                      .state =
                                  1,
                          child: const Text('Choose'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  if (isProgramMode)
                    _ProgramArea(
                      activeProgramId: activeId,
                      timeOfDay: _timeOfDay,
                      appMood: appMood,
                      catalogueAsync: catalogueAsync,
                      mapMood: _mapMood,
                      sessionBuilder: _buildProgramSession,
                      catalogueProgramId: _catalogueProgramId,
                      catalogueDurationDays: _catalogueDurationDays,
                    )
                  else
                    _ChatArea(
                      t: t,
                      controller: _controller,
                      replyState: replyState,
                      onSend: (text) => ref
                          .read(coachLlmProvider.notifier)
                          .generateReply(text),
                    ),

                  const SizedBox(height: 12),

                  // Micro-action system
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
          ),
        ],
      ),
    );
  }
}

class _ProgramArea extends ConsumerStatefulWidget {
  const _ProgramArea({
    required this.activeProgramId,
    required this.timeOfDay,
    required this.appMood,
    required this.catalogueAsync,
    required this.mapMood,
    required this.sessionBuilder,
    required this.catalogueProgramId,
    required this.catalogueDurationDays,
  });

  final String activeProgramId;
  final ProgramTimeOfDay timeOfDay;
  final app.AlignaMood appMood;
  final AsyncValue<List<dynamic>> catalogueAsync;

  final String Function(app.AlignaMood) mapMood;

  final Widget Function(
    BuildContext context,
    ProgramSessionBundle bundle,
    ProgramSessionRequest req,
  )
  sessionBuilder;

  final String? Function(dynamic item) catalogueProgramId;
  final int? Function(dynamic item) catalogueDurationDays;

  @override
  ConsumerState<_ProgramArea> createState() => _ProgramAreaState();
}

class _ProgramAreaState extends ConsumerState<_ProgramArea> {
  List<String>? _displayedLines;
  String? _lastSessionKey;

  Timer? _loadingWatchdog;
  bool _showLoadRecovery = false;

  bool _didProbe = false;

  @override
  void dispose() {
    _loadingWatchdog?.cancel();
    super.dispose();
  }

  void _armLoadingWatchdog() {
    if (_loadingWatchdog != null) return; // do not re-arm on every rebuild
    _showLoadRecovery = false;

    _loadingWatchdog = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _showLoadRecovery = true);
    });
  }

  void _clearLoadingWatchdog() {
    _loadingWatchdog?.cancel();
    _loadingWatchdog = null;
    _showLoadRecovery = false;
  }

  String _guessScriptAssetPath(String programId) {
    return 'assets/data/program_scripts/$programId.v1.json';
  }

  Future<void> _probeProviderOnce(ProgramSessionRequest req) async {
    if (_didProbe) return;
    _didProbe = true;

    unawaited(() async {
      try {
        debugPrint('[PROGRAM] probe start: $req');
        await ref
            .read(programSessionBundleProvider(req).future)
            .timeout(const Duration(seconds: 6));
        debugPrint('[PROGRAM] probe ok: $req');
      } catch (e, st) {
        debugPrint('[PROGRAM] probe FAILED: $e');
        debugPrint('$st');
        if (!mounted) return;
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.catalogueAsync.valueOrNull ?? const [];

    int durationDays = 7;
    for (final p in items) {
      final pid = widget.catalogueProgramId(p);
      if (pid == widget.activeProgramId) {
        final d = widget.catalogueDurationDays(p);
        if (d != null && d > 0) durationDays = d;
        break;
      }
    }

    final req = ProgramSessionRequest(
      programId: widget.activeProgramId,
      durationDays: durationDays,
      timeOfDay: widget.timeOfDay,
      mood: widget.mapMood(widget.appMood),
    );

    final asyncBundle = ref.watch(programSessionBundleProvider(req));

    return asyncBundle.when(
      data: (bundle) {
        _clearLoadingWatchdog();
        _didProbe = false;
        return _buildEnhancedSession(context, bundle, req);
      },
      loading: () {
        _armLoadingWatchdog();
        _probeProviderOnce(req);

        if (_displayedLines != null && _displayedLines!.isNotEmpty) {
          final fallbackSession = ProgramSession(
            programId: req.programId,
            day: 1,
            timeOfDay: req.timeOfDay,
            estimatedMinutes: 1,
            intent: '',
            messages: _displayedLines!,
            microAction: null,
            reflection: null,
            resumeCopy: const ResumeCopy(
              neutral: 'Welcome back.',
              warm: 'Good to have you here.',
            ),
            llmPromptKey: null,
          );

          final fallbackBundle = ProgramSessionBundle(
            progress: ProgramProgress(
              programId: req.programId,
              lastCompletedDay: 0,
              startedAt: DateTime.now().toUtc(),
            ),
            plan: ProgramResumePlan(
              dayToShow: 1,
              showResumeLine: false,
              resumeTone: 'neutral',
              gapDays: 0,
            ),
            session: fallbackSession,
          );

          return widget.sessionBuilder(context, fallbackBundle, req);
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TypingBubble(),
              if (_showLoadRecovery) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Your program content is loading.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If this keeps happening, tap Retry. Then open Debug details.',
                          style: TextStyle(color: AlignaColors.subtext),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _didProbe = false;
                              _loadingWatchdog?.cancel();
                              _loadingWatchdog = null;
                              _showLoadRecovery = false;
                            });
                            ref.invalidate(programSessionBundleProvider(req));
                          },
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () {
                            final asset = _guessScriptAssetPath(req.programId);
                            debugPrint('[PROGRAM] DEBUG DETAILS');
                            debugPrint(' activeProgramId: ${req.programId}');
                            debugPrint(' durationDays: ${req.durationDays}');
                            debugPrint(' timeOfDay: ${req.timeOfDay}');
                            debugPrint(' mood: ${req.mood}');
                            debugPrint(' guessedAssetPath: $asset');

                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Debug details'),
                                content: SelectableText(
                                  'req:\n$req\n\n'
                                  'guessed script asset:\n$asset\n\n'
                                  'Next check:\n'
                                  '1) Does this file exist in assets?\n'
                                  '2) Is assets/data/program_scripts/ in pubspec assets?\n'
                                  '3) Do you see [SCRIPT] loaded OK logs?\n',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Debug details'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      error: (e, st) {
        _clearLoadingWatchdog();
        debugPrint('[PROGRAM] provider error: $e');
        debugPrint('$st');

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Program load failed',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(e.toString()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(programSessionBundleProvider(req));
                    },
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Prefs.setActiveProgramId('');
                      ref.read(app.activeProgramIdProvider.notifier).state =
                          null;
                    },
                    child: const Text('Clear program'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSession(
    BuildContext context,
    ProgramSessionBundle bundle,
    ProgramSessionRequest req,
  ) {
    final session = bundle.session;
    final fallbackLines = session.messages;

    final sessionKey =
        '${session.programId}_${session.day}_${session.timeOfDay}';

    if (_lastSessionKey != sessionKey) {
      _lastSessionKey = sessionKey;
      _displayedLines = null;
    }

    if (_displayedLines == null) {
      _displayedLines = fallbackLines;

      // Attempt enhancement only if llmPromptKey exists.
      if (session.llmPromptKey != null) {
        _enhanceLines(session, req);
      }
    }

    final enhancedSession = ProgramSession(
      programId: session.programId,
      day: session.day,
      timeOfDay: session.timeOfDay,
      estimatedMinutes: session.estimatedMinutes,
      intent: session.intent,
      messages: _displayedLines!,
      microAction: session.microAction,
      reflection: session.reflection,
      resumeCopy: session.resumeCopy,
      llmPromptKey: session.llmPromptKey,
    );

    final enhancedBundle = ProgramSessionBundle(
      progress: bundle.progress,
      plan: bundle.plan,
      session: enhancedSession,
    );

    return widget.sessionBuilder(context, enhancedBundle, req);
  }

  void _enhanceLines(ProgramSession session, ProgramSessionRequest req) {
    unawaited(() async {
      try {
        final svc = ref.read(coachEnhanceServiceProvider);

        final res = await svc
            .enhance(
              request: CoachEnhanceRequest(
                programId: widget.activeProgramId,
                day: session.day,
                blockId: req.timeOfDay.jsonKey,
                moodKey: req.mood,
                language: 'en',
                fallbackLines: session.messages,
                maxLines: session.messages.length,
              ),
            )
            .timeout(const Duration(seconds: 8));

        if (!mounted) return;

        setState(() {
          _displayedLines = res.lines.isNotEmpty ? res.lines : session.messages;
        });
      } catch (e) {
        debugPrint('[ENHANCE] failed (non-fatal): $e');
      }
    }());
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
            ElevatedButton(
              onPressed: onStart,
              child: const Text("Let’s do it"),
            ),
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
