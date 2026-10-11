import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<bool?> hasProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      final row =
          await _db.from('users').select('id').eq('id', user.id).maybeSingle();
      return row != null;
    } catch (e) {
      debugPrint('hasProfile error: $e');
      return null;
    }
  }

  Future<bool> saveProfile({
    required String university,
    required int course,
    required int roleId,
    required List<int> disciplineIds,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;

    final meta = user.userMetadata ?? {};

    try {
      await _db.from('users').upsert({
        'id': user.id,
        'first_name': (meta['first_name'] as String?) ?? '',
        'last_name': (meta['last_name'] as String?) ?? '',
        'university': university,
        'course': course,
        'role_id': roleId,
      });

      await _db.from('user_disciplines').delete().eq('user_id', user.id);
      if (disciplineIds.isNotEmpty) {
        await _db.from('user_disciplines').insert([
          for (final id in disciplineIds)
            {'user_id': user.id, 'discipline_id': id},
        ]);
      }
      return true;
    } catch (e) {
      debugPrint('saveProfile error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _db
          .from('users')
          .select(
            'id, first_name, last_name, university, course, description, hourly_rate, '
            'role:roles(id, name), '
            'user_disciplines(discipline:disciplines(id, name))',
          )
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  Future<num?> getRating(String userId) async {
    try {
      final rows = await _db
          .from('reviews')
          .select('rating')
          .eq('reviewed_user_id', userId);
      if (rows.isEmpty) return null;
      final sum = rows.fold<num>(0, (acc, row) => acc + (row['rating'] as num));
      return sum / rows.length;
    } catch (e) {
      debugPrint('getRating error: $e');
      return null;
    }
  }

  Future<bool> addDisciplines(List<int> disciplineIds) async {
    final user = _db.auth.currentUser;
    if (user == null || disciplineIds.isEmpty) return false;
    try {
      await _db.from('user_disciplines').insert([
        for (final id in disciplineIds)
          {'user_id': user.id, 'discipline_id': id},
      ]);
      return true;
    } catch (e) {
      debugPrint('addDisciplines error: $e');
      return false;
    }
  }

  Future<bool> removeDiscipline(int disciplineId) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      await _db
          .from('user_disciplines')
          .delete()
          .eq('user_id', user.id)
          .eq('discipline_id', disciplineId);
      return true;
    } catch (e) {
      debugPrint('removeDiscipline error: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String university,
    required int course,
    required int roleId,
    required num? hourlyRate,
    required String description,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      await _db.from('users').update({
        'first_name': firstName,
        'last_name': lastName,
        'university': university,
        'course': course,
        'role_id': roleId,
        'hourly_rate': hourlyRate,
        'description': description.isEmpty ? null : description,
      }).eq('id', user.id);
      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    }
  }
}
