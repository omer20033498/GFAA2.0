import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The standard raised-surface treatment for cards/tiles across the app —
/// a subtle border plus an extremely soft green-tinted shadow (not black),
/// so cards read as distinct surfaces against the page background without
/// looking heavy or "dashboard-y". Client's exact spec: border `#D8DED7`,
/// shadow `0 2px 8px rgba(53, 92, 69, 0.06)`.
///
/// Wraps [child] in a tappable [InkWell] when [onTap] is given, otherwise
/// just the decorated surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 14,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.coolWhite,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F355C45), offset: Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
