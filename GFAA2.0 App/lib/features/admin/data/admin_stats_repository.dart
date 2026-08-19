import '../../../core/supabase/supabase_client.dart';
import 'admin_stats.dart';

class AdminStatsRepository {
  /// Calls the `admin_dashboard_stats()` Postgres function (migration
  /// 0011) rather than querying tables directly — it's the only way to
  /// read the user/checkin counts without an admin-read RLS policy on
  /// those tables, which would expose more than a count (see the
  /// migration's comment).
  Future<AdminStats> fetchStats() async {
    final result = await supabase.rpc('admin_dashboard_stats');
    return AdminStats.fromMap(result as Map<String, dynamic>);
  }
}
