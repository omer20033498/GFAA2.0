import '../../../core/supabase/supabase_client.dart';
import 'bug_report.dart';

class BugReportRepository {
  Future<void> submit({required String userId, required String email, required String body}) {
    return supabase.from('bug_reports').insert({
      'user_id': userId,
      'email': email,
      'body': body,
    });
  }

  /// Admin-only (enforced by RLS) — newest first.
  Future<List<BugReport>> fetchAll() async {
    final rows = await supabase.from('bug_reports').select().order('created_at', ascending: false);
    return rows.map(BugReport.fromMap).toList();
  }

  Future<void> setStatus({required String id, required BugReportStatus status}) async {
    final updated = await supabase.from('bug_reports').update({'status': status.key}).eq('id', id).select();
    if (updated.isEmpty) {
      throw StateError("Couldn't find that report to update.");
    }
  }
}
