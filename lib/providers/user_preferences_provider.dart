import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final selectedFrequenciesProvider = FutureProvider<List<String>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const [];

  try {
    final response = await Supabase.instance.client
        .from('user_preferences')
        .select('selected_frequencies')
        .eq('user_id', user.id)
        .maybeSingle();

    final raw = response?['selected_frequencies'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return const [];
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[UserPreferences] Failed to load frequencies: $e');
    }
    return const [];
  }
});
