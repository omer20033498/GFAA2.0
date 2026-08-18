import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/home_menu_row.dart';
import '../../auth/application/auth_providers.dart';
import '../../community/presentation/community_moderation_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../messages/presentation/admin_messages_screen.dart';

/// The `admin`-role home. Same minimal, one-row-per-feature pattern as
/// `HomeScreen` — grows as more admin capabilities land (resource uploads,
/// practitioner approval), eventually consolidating into the full Admin
/// Dashboard (CLAUDE.md finalised feature 9).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
            const HomeMenuRow(icon: Icons.auto_awesome_outlined, label: 'More coming soon'),
          ],
        ),
      ),
    );
  }
}
