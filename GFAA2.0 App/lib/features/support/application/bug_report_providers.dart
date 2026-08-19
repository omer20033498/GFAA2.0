import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bug_report.dart';
import '../data/bug_report_repository.dart';

final bugReportRepositoryProvider = Provider((ref) => BugReportRepository());

/// Admin's bug-report queue.
final bugReportsProvider = FutureProvider<List<BugReport>>((ref) {
  return ref.watch(bugReportRepositoryProvider).fetchAll();
});
