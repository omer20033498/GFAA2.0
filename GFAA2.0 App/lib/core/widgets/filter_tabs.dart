import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A row of pill-shaped filter tabs (see e.g. the Daily Messages
/// All/Saved/Favourites filter, or Community's Pending/Approved/Rejected).
class FilterTabs<T> extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options) ...[
          _FilterChip(
            label: labelOf(option),
            selected: option == selected,
            onTap: () => onChanged(option),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepGreen : AppColors.coolWhite,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.offWhite : AppColors.nearBlack,
          ),
        ),
      ),
    );
  }
}
