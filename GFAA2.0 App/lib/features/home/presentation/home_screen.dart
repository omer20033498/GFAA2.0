import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../training/presentation/training_screen.dart';

/// The `user`-role home. Deliberately minimal — a menu of feature entry
/// points, extended one row at a time as each feature branch lands (see
/// CLAUDE.md's finalised feature list for what's still to come).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            _HomeMenuRow(
              icon: Icons.school_outlined,
              label: 'Training',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrainingScreen()),
              ),
            ),
            const SizedBox(height: 10),
            const _HomeMenuRow(icon: Icons.auto_awesome_outlined, label: 'More coming soon'),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuRow extends StatelessWidget {
  const _HomeMenuRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.coolWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: AppColors.deepGreen),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
                if (enabled)
                  Icon(Icons.chevron_right, size: 18, color: AppColors.nearBlack.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
