import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/leaf_branch.dart';
import '../../../core/widgets/mountain_footer.dart';
import '../../auth/application/auth_providers.dart';
import '../../support/presentation/report_bug_sheet.dart';
import 'about_gfaa_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_account_screen.dart';
import 'terms_of_use_screen.dart';

/// Slide-over profile panel — reachable from anywhere in the `user`
/// experience via the bottom nav's Profile item (see `UserShell`), a
/// standard `Scaffold.drawer`, not a fifth screen.
class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  void _push(BuildContext context, Widget screen) {
    // Capture the Navigator before popping the drawer closed — `context`
    // may be unmounted immediately after `pop()`, so look it up once and
    // reuse the captured NavigatorState rather than calling
    // `Navigator.of(context)` a second time.
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => screen));
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
            // Header + menu rows scroll independently of the footer below —
            // on a short screen the fixed footer (illustration, version,
            // Log Out) was overflowing when there wasn't room left for it
            // after a `Spacer()` inside a single non-scrolling Column.
            Expanded(
              child: SingleChildScrollView(
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
                      onTap: () => _push(context, const ProfileAccountScreen()),
                    ),
                    const Divider(height: 1, indent: 24, endIndent: 24),
                    _DrawerRow(
                      icon: Icons.info_outline,
                      label: 'About GFAA',
                      onTap: () => _push(context, const AboutGfaaScreen()),
                    ),
                    const Divider(height: 1, indent: 24, endIndent: 24),
                    _DrawerRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Use',
                      onTap: () => _push(context, const TermsOfUseScreen()),
                    ),
                    const Divider(height: 1, indent: 24, endIndent: 24),
                    _DrawerRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Privacy Policy',
                      onTap: () => _push(context, const PrivacyPolicyScreen()),
                    ),
                    const Divider(height: 1, indent: 24, endIndent: 24),
                    _DrawerRow(
                      icon: Icons.bug_report_outlined,
                      label: 'Report a Bug',
                      onTap: () {
                        // Same capture-before-pop reasoning as `_push` —
                        // reuse the Navigator's own (still-mounted) context
                        // for the sheet rather than the drawer's context,
                        // which is about to close.
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        showReportBugSheet(navigator.context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const MountainFooter(height: 80),
            const SizedBox(height: 8),
            Text(
              'App Version 1.0.0',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
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
            Icon(Icons.chevron_right, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
