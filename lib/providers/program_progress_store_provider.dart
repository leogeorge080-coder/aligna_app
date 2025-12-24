import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/program_progress_store.dart';

final programProgressStoreProvider = Provider<ProgramProgressStore>((ref) {
  return ProgramProgressStore();
});
