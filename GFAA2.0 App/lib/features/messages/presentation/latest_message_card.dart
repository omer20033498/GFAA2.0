import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/message_providers.dart';
import 'message_actions_row.dart';
import 'messages_screen.dart';

/// A preview of the single most recent daily message, for the Home screen —
/// save/favourite/share right there, no need to open the full Daily
/// Messages screen just to act on today's message.
///
/// Renders nothing while loading, on error, or when there are no messages
/// yet — a loading spinner or error banner would be more disruptive than
/// useful on a landing screen, and the full Daily Messages screen (reachable
/// from the menu below) already surfaces those properly.
class LatestMessageCard extends ConsumerWidget {
  const LatestMessageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesWithStateProvider).value;
    if (messages == null || messages.isEmpty) return const SizedBox.shrink();
    final latest = messages.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's message",
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              latest.message.body,
              style: const TextStyle(fontSize: 16, height: 1.6, letterSpacing: 0.1, color: AppColors.nearBlack),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: MessageActionsRow(item: latest)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
