import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/coach_enhance_service.dart';

const supabaseUrl = 'https://tfyzjqrgwjiturirjrpt.supabase.co';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // anon public key only

final coachEnhanceServiceProvider = Provider<CoachEnhanceService>((ref) {
  return CoachEnhanceService(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );
});
