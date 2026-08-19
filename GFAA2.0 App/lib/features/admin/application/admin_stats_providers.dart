import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_stats.dart';
import '../data/admin_stats_repository.dart';

final adminStatsRepositoryProvider = Provider((ref) => AdminStatsRepository());

final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  return ref.watch(adminStatsRepositoryProvider).fetchStats();
});
