import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A soft-filled, tappable card used for multi-select choices (onboarding
/// questions). Deliberately not a checkbox list — selection is shown via
/// fill + border colour, matching the brand's calm, low-chrome feel.
class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.softSage : AppColors.coolWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.deepGreen : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? AppColors.deepGreen : AppColors.secondaryText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
