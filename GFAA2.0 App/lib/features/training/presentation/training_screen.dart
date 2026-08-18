import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../training_content.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  Future<void> _openLink(BuildContext context, String url) async {
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open that link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final row in trainingRows) ...[
              _TrainingCard(row: row, onLearnMore: () => _openLink(context, row.url)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.row, required this.onLearnMore});

  final TrainingRow row;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.coolWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.title,
            style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(row.description, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          InkWell(
            onTap: onLearnMore,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Learn more',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_outward, size: 14, color: AppColors.deepGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
