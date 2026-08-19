import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../../core/widgets/app_card.dart';
import '../application/bug_report_providers.dart';
import '../data/bug_report.dart';

class BugReportsScreen extends ConsumerWidget {
  const BugReportsScreen({super.key});

  Future<void> _resolve(WidgetRef ref, BugReport report) async {
    await ref.read(bugReportRepositoryProvider).setStatus(id: report.id, status: BugReportStatus.resolved);
    ref.invalidate(bugReportsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(bugReportsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bug Reports')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(bugReportsProvider.future),
          child: reportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [Padding(padding: const EdgeInsets.all(32), child: Text('$error'))],
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(padding: EdgeInsets.all(32), child: Text('No bug reports yet.')),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                itemCount: reports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final resolved = report.status == BugReportStatus.resolved;
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatRelativeDate(report.createdAt),
                                style: textTheme.labelSmall,
                              ),
                            ),
                            if (resolved)
                              const Text('Resolved', style: TextStyle(color: AppColors.deepGreen, fontSize: 12))
                            else
                              TextButton(
                                onPressed: () => _resolve(ref, report),
                                child: const Text('Mark resolved'),
                              ),
                          ],
                        ),
                        Text(report.body, style: textTheme.bodyLarge),
                        const SizedBox(height: 6),
                        Text(report.email, style: textTheme.labelSmall),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
