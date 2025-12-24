import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/program_progress_actions.dart';
import 'program_progress_store_provider.dart'; // ✅ this is where programProgressStoreProvider lives

final programProgressActionsProvider = Provider<ProgramProgressActions>((ref) {
  final store = ref.read(programProgressStoreProvider);
  return ProgramProgressActions(store);
});
