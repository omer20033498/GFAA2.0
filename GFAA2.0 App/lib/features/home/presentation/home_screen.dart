import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../../auth/application/auth_providers.dart';
import '../../journal/presentation/journal_list_screen.dart';
import '../../messages/presentation/latest_message_card.dart';
import '../../practitioners/presentation/specialist_directory_screen.dart';
import '../../training/presentation/training_screen.dart';

/// The GFAA resources hub — per the user's call, this is a single outbound
/// link (not a browsable/categorised in-app list), same "open externally"
/// pattern as Training's rows.
const _resourcesUrl = 'https://grieffirstaid.au/resources/';

/// The Home *tab*'s root content (see `UserShell`) — a greeting, today's
/// message preview, and a grid of feature entry points. Check-ins and
/// Community moved to their own bottom-nav tabs; the rest (Journal,
/// Training, Resources, Find a Specialist) are reached from the grid here,
/// pushed onto this tab's own navigation stack so the back arrow works
/// normally and the bottom bar stays put.
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const GfaaLogo(height: 28),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, ${profile?.effectiveDisplayName ?? ''}',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text("You're not alone.\nWe're here to walk with you.", style: textTheme.bodyMedium),
                const SizedBox(height: 6),
                Container(width: 36, height: 3, color: AppColors.neonYellow),
              ],
            ),
            const SizedBox(height: 24),
            const LatestMessageCard(),
            Text('Explore support & tools', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [
                _FeatureCard(
                  icon: Icons.edit_note,
                  label: 'Journal',
                  description: 'Write, reflect\nand process',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JournalListScreen()),
                  ),
                ),
                _FeatureCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Resources',
                  description: 'Articles, videos\nand tools',
                  onTap: () => _openResources(context),
                ),
                _FeatureCard(
                  icon: Icons.school_outlined,
                  label: 'Training',
                  description: 'Courses and\nworkshops',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TrainingScreen()),
                  ),
                ),
                _FeatureCard(
                  icon: Icons.favorite_border,
                  label: 'Find a Specialist',
                  description: 'Find professional\ngrief support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SpecialistDirectoryScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.deepGreen),
          ),
          const SizedBox(height: 12),
          Text(label, style: textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(description, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
