import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/program_script_loader.dart';

typedef JsonMap = Map<String, dynamic>;

final programScriptProvider = FutureProvider.family<JsonMap, String>((
  ref,
  assetPath,
) async {
  return ProgramScriptLoader.loadFromAssetPath(assetPath);
});
