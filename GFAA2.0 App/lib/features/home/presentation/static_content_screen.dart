import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shared shape for the drawer's plain-text destinations (About GFAA,
/// Terms of Use, Privacy Policy) — a title and a body of paragraphs.
class StaticContentScreen extends StatelessWidget {
  const StaticContentScreen({super.key, required this.title, required this.paragraphs, this.draftNotice});

  final String title;
  final List<String> paragraphs;

  /// Shown as a small banner above the content for copy that's a
  /// placeholder pending the client's own wording (About, Privacy Policy).
  final String? draftNotice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (draftNotice != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.softSage, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, size: 18, color: AppColors.deepGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(draftNotice!, style: textTheme.labelSmall)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            for (final paragraph in paragraphs) ...[
              Text(paragraph, style: textTheme.bodyLarge?.copyWith(height: 1.6)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
