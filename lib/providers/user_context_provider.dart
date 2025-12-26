import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_context.dart';
import '../services/tarot_service.dart';
import '../services/user_context_service.dart';

class UserContextController extends StateNotifier<AsyncValue<UserContext>> {
  UserContextController() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final ctx = await UserContextService.fetchContext();
    state = AsyncValue.data(ctx);
  }

  Future<void> updateFromTarot(TarotCard card) async {
    final next = await UserContextService.upsertContext(
      lastTarotCard: card.cardName.isNotEmpty ? card.cardName : 'neutral',
      activeFrequency:
          card.trackType != null && card.trackType!.trim().isNotEmpty
              ? card.trackType!.trim()
              : 'neutral',
    );
    state = AsyncValue.data(next);
  }
}

final userContextProvider =
    StateNotifierProvider<UserContextController, AsyncValue<UserContext>>(
  (ref) => UserContextController(),
);
