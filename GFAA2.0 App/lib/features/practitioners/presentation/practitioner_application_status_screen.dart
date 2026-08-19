import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../../auth/application/auth_providers.dart';
import '../data/practitioner.dart';

/// Shown instead of the normal user Home/onboarding while an account's
/// practitioner application is pending, or after it's been
/// rejected/suspended — see `_AuthGate`. An approved application promotes
/// the account to the `practitioner` role server-side (migration 0008's
/// sync_practitioner_role trigger), which routes to the real Practitioner
/// Portal instead of here.
class PractitionerApplicationStatusScreen extends ConsumerWidget {
  const PractitionerApplicationStatusScreen({super.key, required this.practitioner});

  final Practitioner practitioner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, title, message) = switch (practitioner.status) {
      PractitionerStatus.pending => (
          Icons.hourglass_top_outlined,
          'Application under review',
          "Thanks for applying. We'll review your details — there's nothing else to do right now. "
              'Check back by logging in again.',
        ),
      PractitionerStatus.rejected => (
          Icons.info_outline,
          "Application wasn't approved",
          "Your application to be listed wasn't approved this time. Contact GFAA if you'd like to know more.",
        ),
      PractitionerStatus.suspended => (
          Icons.pause_circle_outlined,
          'Listing suspended',
          'Your specialist listing has been suspended. Contact GFAA if you have questions.',
        ),
      PractitionerStatus.approved => (
          Icons.check_circle_outline,
          'Approved',
          "You're approved — reopen the app to reach your portal.",
        ),
    };

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GfaaLogo(),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
                  child: Icon(icon, size: 40, color: AppColors.deepGreen),
                ),
                const SizedBox(height: 20),
                Text(title, style: textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
