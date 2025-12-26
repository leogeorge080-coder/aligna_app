import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_event.dart';
import '../services/user_events_service.dart';

final userEventsProvider = StreamProvider<List<UserEvent>>((ref) {
  return UserEventsService.watchRecentEvents();
});
