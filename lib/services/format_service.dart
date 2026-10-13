import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormatService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getFormats() async {
    try {
      return await _db.from('lesson_formats').select('id, name').order('id');
    } catch (e) {
      debugPrint('getFormats error: $e');
      return [];
    }
  }
}