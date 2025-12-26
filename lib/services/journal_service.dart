import 'package:supabase_flutter/supabase_flutter.dart';

class JournalService {
  static final supabase = Supabase.instance.client;

  /// Saves a journal entry to the user_progress table
  static Future<bool> saveJournalEntry({
    required String userId,
    required String programId,
    required int dayNumber,
    required String journalEntryText,
  }) async {
    try {
      final response = await supabase.from('user_progress').insert([
        {
          'user_id': userId,
          'program_id': programId,
          'day_number': dayNumber,
          'journal_entry_text': journalEntryText,
        },
      ]);

      // Update completed_days in user_profiles
      await _updateUserProgress(userId);

      return true;
    } catch (e) {
      print('Error saving journal entry: $e');
      return false;
    }
  }

  /// Updates the completed_days count in user_profiles table
  static Future<void> _updateUserProgress(String userId) async {
    try {
      // Get current completed_days
      final currentProfile = await supabase
          .from('user_profiles')
          .select('completed_days')
          .eq('id', userId)
          .single();

      final currentCompletedDays =
          currentProfile['completed_days'] as int? ?? 0;

      // Increment completed_days
      await supabase
          .from('user_profiles')
          .update({'completed_days': currentCompletedDays + 1})
          .eq('id', userId);
    } catch (e) {
      print('Error updating user progress: $e');
      // Don't fail the journal save if progress update fails
    }
  }

  /// Gets the current user ID from Supabase auth
  static String? getCurrentUserId() {
    final user = supabase.auth.currentUser;
    return user?.id;
  }
}
