import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/program_script_loader.dart';
import '../programs/script_schema.dart';

typedef JsonMap = Map<String, dynamic>;

final programScriptProvider = FutureProvider.family<ProgramScript, String>((
  ref,
  programId,
) async {
  final loader = ProgramScriptLoader();
  return loader.loadByProgramId(programId);
});
