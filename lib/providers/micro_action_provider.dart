import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MicroActionStatus { none, offered, started, skipped, completed }

final microActionTextProvider = StateProvider<String?>((ref) => null);

final microActionStatusProvider = StateProvider<MicroActionStatus>(
  (ref) => MicroActionStatus.none,
);

/// ✅ Use inside PROVIDERS / NOTIFIERS
void resetMicroAction(Ref ref) {
  ref.read(microActionTextProvider.notifier).state = null;
  ref.read(microActionStatusProvider.notifier).state = MicroActionStatus.none;
}

/// ✅ Use inside WIDGETS
void resetMicroActionFromWidget(WidgetRef ref) {
  ref.read(microActionTextProvider.notifier).state = null;
  ref.read(microActionStatusProvider.notifier).state = MicroActionStatus.none;
}

/// ✅ Provider-side helper (Option B)
void offerMicroAction(Ref ref, {required String text}) {
  ref.read(microActionTextProvider.notifier).state = text;
  ref.read(microActionStatusProvider.notifier).state =
      MicroActionStatus.offered;
}
