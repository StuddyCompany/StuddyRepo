import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TutorService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTopTutors({int limit = 10}) async {
    try {
      final res = await _db.rpc('top_tutors', params: {'p_limit': limit});
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getTopTutors error: $e');
      return [];
    }
  }
}
