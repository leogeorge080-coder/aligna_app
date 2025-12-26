import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program.dart';

class ProgramService {
  static final supabase = Supabase.instance.client;

  /// Fetches the UUID from the programs table where slug matches the given slug
  static Future<String?> getProgramIdBySlug(String slug) async {
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(slug);
    if (isUuid) {
      return slug;
    }
    try {
      final response = await supabase
          .from('programs')
          .select('id')
          .eq('slug', slug)
          .single();

      return response['id'] as String?;
    } catch (e) {
      print('Error fetching program ID for slug $slug: $e');
      return null;
    }
  }

  /// Fetches program details by UUID
  static Future<Map<String, dynamic>?> getProgramById(String id) async {
    try {
      final response = await supabase
          .from('programs')
          .select('*')
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      print('Error fetching program by ID $id: $e');
      return null;
    }
  }

  /// Fetches complete Program object by ID
  static Future<Program?> getProgramObjectById(String id) async {
    try {
      final response = await supabase
          .from('programs')
          .select('*')
          .eq('id', id)
          .single();

      return Program.fromJson(response);
    } catch (e) {
      print('Error fetching program object by ID $id: $e');
      return null;
    }
  }

  /// Fetches program by slug
  static Future<Program?> getProgramBySlug(String slug) async {
    try {
      final response = await supabase
          .from('programs')
          .select('*')
          .eq('slug', slug)
          .single();

      return Program.fromJson(response);
    } catch (e) {
      print('Error fetching program by slug $slug: $e');
      return null;
    }
  }

  /// Fetches all active programs
  static Future<List<Program>> getAllPrograms() async {
    print('\u{1F7E1} [ProgramService] getAllPrograms() called');
    try {
      print('\u{1F7E1} [ProgramService] Calling Supabase now...');
      final response = await supabase
          .from('programs')
          .select()
          .order('title');

      print('\u{1F7E2} [ProgramService] Supabase response received');
      print('\u{1F7E2} [ProgramService] Raw response: $response');

      return response.map<Program>((e) => Program.fromJson(e)).toList();
    } catch (e, stack) {
      print('\u{1F534} [ProgramService] ERROR: $e');
      print('\u{1F534} StackTrace: $stack');
      rethrow;
    }
  }
}
