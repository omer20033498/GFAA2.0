import '../../../core/supabase/supabase_client.dart';
import 'daily_message.dart';

class MessageRepository {
  Future<List<DailyMessage>> fetchMessages({int limit = 50}) async {
    final rows = await supabase
        .from('daily_messages')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(DailyMessage.fromMap).toList();
  }

  Future<void> sendMessage({required String adminId, required String body}) {
    return supabase.from('daily_messages').insert({'body': body, 'sent_by_admin_id': adminId});
  }

  /// Cascades to remove this message from every user's saved/favourited
  /// state too (`user_messages.message_id` has `on delete cascade`, see
  /// migration 0005). `.select()` verifies a row was actually deleted —
  /// see journal/checkins repositories for why that check matters.
  Future<void> deleteMessage(String id) async {
    final deleted = await supabase.from('daily_messages').delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw StateError("Couldn't find that message to delete.");
    }
  }

  /// message_id -> (saved, favourited) for every message this user has
  /// touched. A message with no entry here has never been saved/favourited.
  Future<Map<String, ({bool saved, bool favourited})>> fetchUserMessageStates(String userId) async {
    final rows = await supabase
        .from('user_messages')
        .select('message_id, saved, favourited')
        .eq('user_id', userId);
    return {
      for (final row in rows)
        row['message_id'] as String: (saved: row['saved'] as bool, favourited: row['favourited'] as bool),
    };
  }

  /// Upserts only the fields provided — Postgrest's upsert only SETs
  /// columns present in the payload on conflict, so omitted fields (e.g.
  /// `favourited` when only toggling `saved`) keep their existing value
  /// rather than being reset.
  Future<void> setMessageState({
    required String userId,
    required String messageId,
    bool? saved,
    bool? favourited,
    bool markShared = false,
  }) {
    return supabase.from('user_messages').upsert({
      'user_id': userId,
      'message_id': messageId,
      'saved': ?saved,
      'favourited': ?favourited,
      if (markShared) 'shared_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,message_id');
  }
}
