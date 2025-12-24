import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../persistence/prefs.dart';

final activeProgramIdProvider = FutureProvider<String?>((ref) async {
  return Prefs.loadActiveProgramId();
});
