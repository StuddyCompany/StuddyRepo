import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class RoleService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      return await _db.from('roles').select('id, name').order('name');
    } catch (e) {
      debugPrint('getRoles error: $e');
      return [];
    }
  }
}
