import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

/// A number + label tile for a stats grid (see `AdminHomeScreen`). Pass
/// [onTap] to make it link into the screen that number is about — e.g.
/// "Pending applications" opens the review queue directly.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: textTheme.headlineMedium?.copyWith(color: AppColors.deepGreen, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
