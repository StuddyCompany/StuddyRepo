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

  Future<Map<String, dynamic>?> getSchedule(String tutorId) async {
    try {
      return await _db
          .from('tutors')
          .select('work_start, work_end')
          .eq('user_id', tutorId)
          .maybeSingle();
    } catch (e) {
      debugPrint('getSchedule error: $e');
      return null;
    }
  }

  Future<bool> saveSchedule(String start, String end) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      await _db.from('tutors').upsert({
        'user_id': user.id,
        'work_start': start,
        'work_end': end,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('saveSchedule error: $e');
      return false;
    }
  }
}
