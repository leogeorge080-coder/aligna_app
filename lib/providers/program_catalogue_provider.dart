import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/program_catalogue_loader.dart';
import '../models/program_catalogue_item.dart';

final programCatalogueProvider = FutureProvider<List<ProgramCatalogueItem>>((
  ref,
) async {
  final raw =
      await ProgramCatalogueLoader.load(); // returns List<Map<String,dynamic>>
  return raw
      .map((m) => ProgramCatalogueItem.fromJson(m))
      .toList(growable: false);
});
