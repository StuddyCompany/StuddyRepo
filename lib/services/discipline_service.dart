import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DisciplineService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDisciplines() async {
    try {
      return await _db.from('disciplines').select('id, name').order('name');
    } catch (e) {
      debugPrint('getDisciplines error: $e');
      return [];
    }
  }
}
