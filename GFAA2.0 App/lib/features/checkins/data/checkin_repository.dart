import '../../../core/supabase/supabase_client.dart';
import 'checkin.dart';
import 'mood.dart';

class CheckinRepository {
  Future<List<Checkin>> fetchCheckins(String userId, {int limit = 30}) async {
    final rows = await supabase
        .from('checkins')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(Checkin.fromMap).toList();
  }

  Future<void> createCheckin({required String userId, required Mood mood, String? note}) {
    return supabase.from('checkins').insert({
      'user_id': userId,
      'mood': mood.key,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// See journal_repository.dart's `deleteEntry` for why this checks
  /// `.select()` — an RLS mismatch would otherwise fail silently.
  Future<void> deleteCheckin(String id) async {
    final deleted = await supabase.from('checkins').delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw StateError("Couldn't find that check-in to delete.");
    }
  }
}
