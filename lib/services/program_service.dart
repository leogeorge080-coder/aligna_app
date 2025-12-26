import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program.dart';

class ProgramService {
  static final supabase = Supabase.instance.client;

  /// Fetches the UUID from the programs table where slug matches the given slug
  static Future<String?> getProgramIdBySlug(String slug) async {
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
    try {
      print('🔍 [ProgramService] Fetching all programs...');
      final response = await supabase
          .from('programs')
          .select('*')
          .eq('is_active', true)
          .order('title');

      print('🔍 [ProgramService] Raw response: $response');
      final programs = (response as List)
          .map((json) => Program.fromJson(json))
          .toList();
      print('🔍 [ProgramService] Parsed ${programs.length} programs');
      for (final p in programs) {
        print(
          '🔍 [ProgramService] Program: ${p.title} (${p.id}) - track: ${p.track}',
        );
      }
      return programs;
    } catch (e) {
      print('❌ [ProgramService] Error fetching all programs: $e');
      return [];
    }
  }
}
