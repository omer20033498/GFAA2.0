import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/home_menu_row.dart';
import '../../auth/application/auth_providers.dart';
import '../../checkins/presentation/checkins_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../journal/presentation/journal_list_screen.dart';
import '../../messages/presentation/latest_message_card.dart';
import '../../messages/presentation/messages_screen.dart';
import '../../training/presentation/training_screen.dart';

/// The GFAA resources hub — per the user's call, this is a single outbound
/// link (not a browsable/categorised in-app list), same "open externally"
/// pattern as Training's rows.
const _resourcesUrl = 'https://grieffirstaid.au/resources/';

/// The `user`-role home. Deliberately minimal — a menu of feature entry
/// points, extended one row at a time as each feature branch lands (see
/// CLAUDE.md's finalised feature list for what's still to come).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openResources(BuildContext context) async {
    final launched = await launchUrl(Uri.parse(_resourcesUrl), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open that link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
            const LatestMessageCard(),
            HomeMenuRow(
              icon: Icons.campaign_outlined,
              label: 'Daily Messages',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              ),
            ),
            const SizedBox(height: 10),
            HomeMenuRow(
              icon: Icons.edit_note,
              label: 'Journal',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JournalListScreen()),
              ),
            ),
            const SizedBox(height: 10),
            HomeMenuRow(
              icon: Icons.mood_outlined,
              label: 'Check-ins',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckinsScreen()),
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
              icon: Icons.school_outlined,
              label: 'Training',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrainingScreen()),
              ),
            ),
            const SizedBox(height: 10),
            HomeMenuRow(
              icon: Icons.menu_book_outlined,
              label: 'Resources',
              onTap: () => _openResources(context),
            ),
            const SizedBox(height: 10),
            const HomeMenuRow(icon: Icons.auto_awesome_outlined, label: 'More coming soon'),
          ],
        ),
      ),
    );
  }
}
