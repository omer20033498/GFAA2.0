import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GfaaBottomNavItem {
  const GfaaBottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Persistent bottom bar for the signed-in `user` experience (see
/// `UserShell`) — Home / Check-in / Community always switch tabs; Profile
/// is wired by the caller to open the profile drawer instead of a fourth
/// tab, since the reference design shows it as a slide-over panel, not a
/// persistent screen.
class GfaaBottomNav extends StatelessWidget {
  const GfaaBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const items = [
    GfaaBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
    GfaaBottomNavItem(icon: Icons.mood_outlined, label: 'Check-in'),
    GfaaBottomNavItem(icon: Icons.groups_outlined, label: 'Community'),
    GfaaBottomNavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              final item = items[index];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.softSage : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: selected ? AppColors.deepGreen : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppColors.deepGreen : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
