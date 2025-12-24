import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/aligna_mood.dart';
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

  /// Script asset path (versioned).
  final String scriptAssetPath;

  final ProgramTimeOfDay timeOfDay;
  final AlignaMood mood;

  const ProgramSessionRequest({
    required this.programId,
    required this.durationDays,
    required this.scriptAssetPath,
    required this.timeOfDay,
    required this.mood,
  });
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
      // 1) Load script JSON (cached by assetPath)
      final script = await ref.watch(
        programScriptProvider(req.scriptAssetPath).future,
      );

      // 2) Load progress (from SharedPreferences)
      final store = ref.read(programProgressStoreProvider);
      final saved = await store.read(req.programId);

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
    });
