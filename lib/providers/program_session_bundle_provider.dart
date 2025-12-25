import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_progress.dart';
import '../models/program_resume_plan.dart';
import '../models/program_session.dart';

import '../data/program_resume_logic.dart';
import '../data/program_session_selector.dart';
import 'program_progress_store_provider.dart';
import 'program_script_provider.dart';

class ProgramSessionRequest {
  final String programId;
  final int durationDays;

  final ProgramTimeOfDay timeOfDay;
  final String mood;

  const ProgramSessionRequest({
    required this.programId,
    required this.durationDays,
    required this.timeOfDay,
    required this.mood,
  });

  @override
  bool operator ==(Object other) {
    return other is ProgramSessionRequest &&
        other.programId == programId &&
        other.durationDays == durationDays &&
        other.timeOfDay == timeOfDay &&
        other.mood == mood;
  }

  @override
  int get hashCode => Object.hash(programId, durationDays, timeOfDay, mood);
}

class ProgramSessionBundle {
  final ProgramProgress progress;
  final ProgramResumePlan plan;
  final ProgramSession session;

  const ProgramSessionBundle({
    required this.progress,
    required this.plan,
    required this.session,
  });
}

final programSessionBundleProvider =
    FutureProvider.family<ProgramSessionBundle, ProgramSessionRequest>((
      ref,
      req,
    ) async {
      // Hard time limits so we never sit in "loading" indefinitely.
      const scriptTimeout = Duration(seconds: 3);
      const progressTimeout = Duration(seconds: 2);

      try {
        // 1) Load script JSON (cached by programId)
        final script = await ref
            .watch(programScriptProvider(req.programId).future)
            .timeout(scriptTimeout);

        // 2) Load progress (from SharedPreferences)
        final store = ref.read(programProgressStoreProvider);
        final saved = await store.read(req.programId).timeout(progressTimeout);

        final progress =
            saved ??
            ProgramProgress(
              programId: req.programId,
              lastCompletedDay: 0,
              startedAt: DateTime.now().toUtc(),
            );

        // 3) Compute resume plan (which day to show)
        final plan = ProgramResumeLogic.buildPlan(
          progress: progress,
          durationDays: req.durationDays,
        );

        // 4) Select session content (mood + timeOfDay)
        final session = ProgramSessionSelector.getSession(
          script: script,
          day: plan.dayToShow,
          timeOfDay: req.timeOfDay,
          mood: req.mood,
        );

        return ProgramSessionBundle(
          progress: progress,
          plan: plan,
          session: session,
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[ProgramSessionBundle] FAILED for ${req.programId}');
          debugPrint('$e');
          debugPrintStack(stackTrace: st);
        }

        // Fallback: still return a renderable bundle so UI never gets stuck.
        final progress = ProgramProgress(
          programId: req.programId,
          lastCompletedDay: 0,
          startedAt: DateTime.now().toUtc(),
        );

        // Your ProgramResumePlan requires gapDays.
        // We use 0 as safe fallback.
        final plan = ProgramResumePlan(
          dayToShow: 1,
          showResumeLine: false,
          resumeTone: 'neutral',
          gapDays: 0,
        );

        final session = ProgramSession(
          programId: req.programId,
          day: 1,
          timeOfDay: req.timeOfDay,
          estimatedMinutes: 1,
          intent: '',
          messages: const [
            'Let’s take this one step at a time.',
            'Your program content is loading. If this keeps happening, tap Retry.',
          ],
          microAction: null,
          reflection: null,
          resumeCopy: const ResumeCopy(
            neutral: 'Welcome back. We’ll continue gently from today.',
            warm: 'Good to have you here. We’ll pick up softly from today.',
          ),
          llmPromptKey: null,
        );

        return ProgramSessionBundle(
          progress: progress,
          plan: plan,
          session: session,
        );
      }
    });
