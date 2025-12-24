import '../models/program_progress.dart';
import '../data/program_resume_logic.dart';
import 'program_progress_store.dart';

class ProgramProgressActions {
  final ProgramProgressStore store;

  ProgramProgressActions(this.store);

  Future<ProgramProgress> markCompleted({
    required ProgramProgress current,
    required int completedDay,
    required int durationDays,
  }) async {
    final updated = ProgramResumeLogic.markDayCompleted(
      progress: current,
      completedDay: completedDay,
      durationDays: durationDays,
    );
    await store.write(updated);
    return updated;
  }

  Future<ProgramProgress> pause(ProgramProgress current) async {
    final updated = ProgramResumeLogic.pause(progress: current);
    await store.write(updated);
    return updated;
  }

  Future<ProgramProgress> resume(ProgramProgress current) async {
    final updated = ProgramResumeLogic.resume(progress: current);
    await store.write(updated);
    return updated;
  }

  Future<ProgramProgress> restart(ProgramProgress current) async {
    final updated = ProgramResumeLogic.restart(progress: current);
    await store.write(updated);
    return updated;
  }
}
