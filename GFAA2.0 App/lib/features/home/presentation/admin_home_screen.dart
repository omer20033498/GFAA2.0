import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/home_menu_row.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../admin/application/admin_stats_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../community/presentation/community_moderation_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../messages/presentation/admin_messages_screen.dart';
import '../../practitioners/data/practitioner.dart';
import '../../practitioners/presentation/practitioner_review_screen.dart';
import '../../support/presentation/bug_reports_screen.dart';

/// The `admin`-role home. Same minimal, one-row-per-feature pattern as
/// `HomeScreen` — grows as more admin capabilities land (resource uploads,
/// practitioner approval), eventually consolidating into the full Admin
/// Dashboard (CLAUDE.md finalised feature 9).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(adminStatsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text("Couldn't load stats: $error"),
                ),
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.8,
                  children: [
                    StatTile(value: stats.totalUsers, label: 'Total users'),
                    StatTile(value: stats.totalPractitioners, label: 'Live practitioners'),
                    StatTile(value: stats.newUsersThisWeek, label: 'New users this week'),
                    StatTile(value: stats.checkinsThisWeek, label: 'Check-ins this week'),
                    StatTile(
                      value: stats.pendingPractitioners,
                      label: 'Applications awaiting review',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PractitionerReviewScreen()),
                      ),
                    ),
                    StatTile(
                      value: stats.pendingPosts,
                      label: 'Posts awaiting approval',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CommunityModerationScreen()),
                      ),
                    ),
                    StatTile(
                      value: stats.openBugReports,
                      label: 'Open bug reports',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BugReportsScreen()),
                      ),
                    ),
                    StatTile(
                      value: stats.pendingPaymentPractitioners,
                      label: 'Pending/failed payments',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PractitionerReviewScreen(initialTab: PractitionerStatus.approved),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              HomeMenuRow(
                icon: Icons.campaign_outlined,
                label: 'Daily Messages',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminMessagesScreen()),
                ),
              ),
              const SizedBox(height: 10),
              HomeMenuRow(
                icon: Icons.groups_outlined,
                label: 'Community',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommunityScreen()),
                ),
              ),
              const SizedBox(height: 10),
              HomeMenuRow(
                icon: Icons.fact_check_outlined,
                label: 'Moderate Posts',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommunityModerationScreen()),
                ),
              ),
              const SizedBox(height: 10),
              HomeMenuRow(
                icon: Icons.psychology_outlined,
                label: 'Practitioner Applications',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PractitionerReviewScreen()),
                ),
              ),
              const SizedBox(height: 10),
              HomeMenuRow(
                icon: Icons.bug_report_outlined,
                label: 'Bug Reports',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BugReportsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
