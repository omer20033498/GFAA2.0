import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

/// A tappable row for a feature-home menu (see `HomeScreen` and
/// `AdminHomeScreen`) — an icon circle, a label, and a chevron. Pass no
/// [onTap] for a disabled/"coming soon" row.
class HomeMenuRow extends StatelessWidget {
  const HomeMenuRow({super.key, required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 12,
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
            if (enabled) Icon(Icons.chevron_right, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
