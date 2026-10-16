import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _db = Supabase.instance.client;

  static const _columns =
      'id, sender_id, recipient_id, message_text, sent_at, read_at';

  String? get currentUserId => _db.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getConversations() async {
    if (currentUserId == null) return [];
    try {
      final rows = await _db.rpc('my_conversations');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('getConversations error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String partnerId) async {
    final me = currentUserId;
    if (me == null) return [];
    try {
      final rows = await _db
          .from('messages')
          .select(_columns)
          .or('and(sender_id.eq.$me,recipient_id.eq.$partnerId),'
              'and(sender_id.eq.$partnerId,recipient_id.eq.$me)')
          .order('sent_at');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('getMessages error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendMessage(
      String recipientId, String text) async {
    final me = currentUserId;
    if (me == null) return null;
    try {
      return await _db
          .from('messages')
          .insert({
            'sender_id': me,
            'recipient_id': recipientId,
            'message_text': text,
          })
          .select(_columns)
          .single();
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return null;
    }
  }

  Future<void> markRead(String partnerId) async {
    try {
      await _db.rpc('mark_messages_read', params: {'p_partner_id': partnerId});
    } catch (e) {
      debugPrint('markRead error: $e');
    }
  }

  /// [onIncoming] — пришло новое сообщение мне.
  /// [onMyMessageUpdated] — моё сообщение изменилось (например, прочитано).
  RealtimeChannel? subscribe({
    required void Function(Map<String, dynamic> row) onIncoming,
    void Function(Map<String, dynamic> row)? onMyMessageUpdated,
  }) {
    final me = currentUserId;
    if (me == null) return null;

    var channel = _db
        .channel('chat_${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: me,
          ),
          callback: (payload) => onIncoming(payload.newRecord),
        );

    if (onMyMessageUpdated != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'sender_id',
          value: me,
        ),
        callback: (payload) => onMyMessageUpdated(payload.newRecord),
      );
    }

    return channel.subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }
}
