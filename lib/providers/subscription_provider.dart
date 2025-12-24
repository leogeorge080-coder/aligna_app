import 'package:flutter_riverpod/flutter_riverpod.dart';

/// For now: all users are Pro (free).
/// Later: replace implementation with RevenueCat / Supabase entitlement.
final isProProvider = StateProvider<bool>((ref) => true);
