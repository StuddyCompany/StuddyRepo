import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _db = Supabase.instance.client;

  /// [sort]: 'rating' | 'price_asc' | 'price_desc'
  Future<List<Map<String, dynamic>>> searchTutors({
    String query = '',
    String sort = 'rating',
    int limit = 100,
  }) async {
    try {
      final q = query.trim();
      final res = await _db.rpc('search_tutors', params: {
        'p_query': q.isEmpty ? null : q,
        'p_sort': sort,
        'p_limit': limit,
      });
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('searchTutors error: $e');
      return [];
    }
  }

  Future<List<String>> getHistory({int limit = 8}) async {
    try {
      final rows = await _db
          .from('search_history')
          .select('query')
          .order('created_at', ascending: false)
          .limit(40);
      final seen = <String>{};
      final result = <String>[];
      for (final row in rows) {
        final q = (row['query'] as String).trim();
        if (q.isEmpty || !seen.add(q.toLowerCase())) continue;
        result.add(q);
        if (result.length >= limit) break;
      }
      return result;
    } catch (e) {
      debugPrint('getHistory error: $e');
      return [];
    }
  }

  Future<void> saveQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    try {
      await _db.from('search_history').insert({'query': q});
    } catch (e) {
      debugPrint('saveQuery error: $e');
    }
  }

  Future<List<String>> getPopular({int limit = 8}) async {
    try {
      final rows = await _db.rpc('popular_searches', params: {'p_limit': limit});
      return [
        for (final row in rows as List) (row as Map<String, dynamic>)['query'] as String,
      ];
    } catch (e) {
      debugPrint('getPopular error: $e');
      return [];
    }
  }
}
