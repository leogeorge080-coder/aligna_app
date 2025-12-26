import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/program.dart';
import '../services/program_service.dart';

final programCatalogueProvider = FutureProvider<List<Program>>((ref) async {
  return await ProgramService.getAllPrograms();
});
