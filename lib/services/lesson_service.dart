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

  String? lastError;

  Future<List<Map<String, dynamic>>> getMyLessons() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      final rows = await _db
          .from('lessons')
          .select(
            'id, date_time, duration, status_id, student_id, teacher_id, topic, hourly_rate, '
            'discipline:disciplines(name), '
            'format:lesson_formats(name), '
            'teacher:users!lessons_teacher_id_fkey(id, first_name, last_name, avatar_url, hourly_rate), '
            'student:users!lessons_student_id_fkey(id, first_name, last_name, avatar_url), '
            'review:reviews(id, rating)',
          )
          .or('student_id.eq.$userId,teacher_id.eq.$userId')
          .order('date_time');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('getMyLessons error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBusyIntervals(
    String tutorId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final rows = await _db.rpc('tutor_busy_intervals', params: {
        'p_tutor_id': tutorId,
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('getBusyIntervals error: $e');
      return [];
    }
  }

  Future<bool> createRequest({
    required String teacherId,
    required int disciplineId,
    required int? formatId,
    required DateTime startsAt,
    required int duration,
    required String topic,
  }) async {
    lastError = null;
    try {
      await _db.rpc('create_lesson_request', params: {
        'p_teacher_id': teacherId,
        'p_discipline_id': disciplineId,
        'p_format_id': formatId,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_duration': duration,
        'p_topic': topic,
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('createRequest error: ${e.message}');
      final m = e.message;
      if (m.contains('slot_taken')) {
        lastError = 'Это время уже занято, выберите другое';
      } else if (m.contains('past_time')) {
        lastError = 'Это время уже прошло';
      } else if (m.contains('self_booking')) {
        lastError = 'Нельзя записаться к самому себе';
      } else {
        lastError = 'Не удалось отправить заявку';
      }
      return false;
    } catch (e) {
      debugPrint('createRequest error: $e');
      lastError = 'Нет связи с сервером';
      return false;
    }
  }

  Future<bool> setStatus(int lessonId, int statusId) async {
    try {
      final res = await _db.rpc('set_lesson_status', params: {
        'p_lesson_id': lessonId,
        'p_status_id': statusId,
      });
      return res == true;
    } catch (e) {
      debugPrint('setStatus error: $e');
      return false;
    }
  }

  Future<int> countActiveAsTeacher() async {
    final userId = currentUserId;
    if (userId == null) return 0;
    try {
      final rows = await _db
          .from('lessons')
          .select('id')
          .eq('teacher_id', userId)
          .inFilter('status_id', [1, 2]).gte(
              'date_time', DateTime.now().toUtc().toIso8601String());
      return rows.length;
    } catch (e) {
      debugPrint('countActiveAsTeacher error: $e');
      return 0;
    }
  }

  Future<bool> createReview(int lessonId, int rating, String comment) async {
    lastError = null;
    try {
      await _db.rpc('create_review', params: {
        'p_lesson_id': lessonId,
        'p_rating': rating,
        'p_comment': comment,
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('createReview error: ${e.message}');
      if (e.message.contains('already_reviewed')) {
        lastError = 'Отзыв на это занятие уже оставлен';
      } else if (e.message.contains('not_finished')) {
        lastError = 'Отзыв можно оставить после занятия';
      } else {
        lastError = 'Не удалось отправить отзыв';
      }
      return false;
    } catch (e) {
      debugPrint('createReview error: $e');
      lastError = 'Нет связи с сервером';
      return false;
    }
  }
}
