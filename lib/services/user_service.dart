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
}
