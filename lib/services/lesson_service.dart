import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonService {
  final SupabaseClient _db = Supabase.instance.client;

  String? get currentUserId => _db.auth.currentUser?.id;

  Future<Map<String, dynamic>?> getNearestLesson() async {
    final userId = currentUserId;
    if (userId == null) return null;
    try {
      return await _db
          .from('lessons')
          .select(
            'id, date_time, student_id, teacher_id, '
            'discipline:disciplines(name), '
            'teacher:users!lessons_teacher_id_fkey(first_name, last_name), '
            'student:users!lessons_student_id_fkey(first_name, last_name)',
          )
          .or('student_id.eq.$userId,teacher_id.eq.$userId')
          .inFilter('status_id', [1, 2])
          .gte('date_time', DateTime.now().toUtc().toIso8601String())
          .order('date_time')
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('getNearestLesson error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingLessons({int limit = 3}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      final rows = await _db
          .from('lessons')
          .select(
            'id, date_time, student_id, teacher_id, '
            'discipline:disciplines(name), '
            'teacher:users!lessons_teacher_id_fkey(first_name, last_name), '
            'student:users!lessons_student_id_fkey(first_name, last_name)',
          )
          .or('student_id.eq.$userId,teacher_id.eq.$userId')
          .inFilter('status_id', [1, 2])
          .gte('date_time', DateTime.now().toUtc().toIso8601String())
          .order('date_time')
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('getUpcomingLessons error: $e');
      return [];
    }
  }
}
