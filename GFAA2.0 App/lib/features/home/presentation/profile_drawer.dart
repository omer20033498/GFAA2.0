import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/leaf_branch.dart';
import '../../../core/widgets/mountain_footer.dart';
import '../../auth/application/auth_providers.dart';

/// Slide-over profile panel — reachable from anywhere in the `user`
/// experience via the bottom nav's Profile item (see `UserShell`), a
/// standard `Scaffold.drawer`, not a fifth screen. The five menu rows
/// (Profile & Account, About GFAA, Terms of Use, Privacy Policy, Report a
/// Bug) are visual-only for now — where each should actually lead is a
/// separate, deliberately deferred decision.
class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppColors.offWhite,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
                    child: const Icon(Icons.person_outline, size: 30, color: AppColors.deepGreen),
                  ),
                  const Expanded(child: LeafBranch()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: profileAsync.when(
                loading: () => const SizedBox(height: 32),
                error: (error, _) => const SizedBox.shrink(),
                data: (profile) => profile == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: textTheme.bodyMedium),
                          Text(profile.effectiveDisplayName, style: textTheme.headlineSmall),
                        ],
                      ),
              ),
            ),
            const Divider(height: 1),
            _DrawerRow(
              icon: Icons.person_outline,
              label: 'Profile & Account',
              onTap: () => _comingSoon(context, 'Profile & Account'),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
            _DrawerRow(
              icon: Icons.info_outline,
              label: 'About GFAA',
              onTap: () => _comingSoon(context, 'About GFAA'),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
            _DrawerRow(
              icon: Icons.description_outlined,
              label: 'Terms of Use',
              onTap: () => _comingSoon(context, 'Terms of Use'),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
            _DrawerRow(
              icon: Icons.verified_user_outlined,
              label: 'Privacy Policy',
              onTap: () => _comingSoon(context, 'Privacy Policy'),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
            _DrawerRow(
              icon: Icons.bug_report_outlined,
              label: 'Report a Bug',
              onTap: () => _comingSoon(context, 'Report a Bug'),
            ),
            const Spacer(),
            const MountainFooter(),
            const SizedBox(height: 12),
            Text(
              'App Version 1.0.0',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: OutlinedButton.icon(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.deepGreen),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            Icon(Icons.chevron_right, size: 18, color: AppColors.nearBlack.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
