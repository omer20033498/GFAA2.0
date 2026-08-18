import '../../../core/supabase/supabase_client.dart';
import 'journal_entry.dart';

class JournalRepository {
  Future<List<JournalEntry>> fetchEntries(String userId) async {
    final rows = await supabase
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<void> createEntry({required String userId, required String body}) {
    return supabase.from('journal_entries').insert({'user_id': userId, 'body': body});
  }

  /// `.select()` makes Postgres report back which row(s) it actually
  /// touched. Without it, an update that matches zero rows (e.g. a stale
  /// `id`, or an RLS mismatch) succeeds silently and looks like nothing
  /// happened — this throws instead so the screen can show a real error.
  Future<void> updateEntry({required String id, required String body}) async {
    final updated = await supabase
        .from('journal_entries')
        .update({'body': body, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select();
    if (updated.isEmpty) {
      throw StateError("Couldn't find that entry to update.");
    }
  }

  /// See [updateEntry] — same reasoning for delete.
  Future<void> deleteEntry(String id) async {
    final deleted = await supabase.from('journal_entries').delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw StateError("Couldn't find that entry to delete.");
    }
  }
}
