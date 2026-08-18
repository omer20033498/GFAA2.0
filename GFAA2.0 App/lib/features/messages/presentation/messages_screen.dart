import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../application/message_providers.dart';
import '../data/message_with_state.dart';
import 'message_actions_row.dart';
import 'message_filter.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  MessageFilter _filter = MessageFilter.all;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesWithStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Messages')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(messagesWithStateProvider.future),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: FilterTabs<MessageFilter>(
                  options: MessageFilter.values,
                  labelOf: (filter) => filter.label,
                  selected: _filter,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ScrollableMessage(message: '$error'),
                  data: (messages) {
                    final filtered = applyMessageFilter(messages, _filter);
                    if (filtered.isEmpty) {
                      return _ScrollableMessage(
                        message: _filter == MessageFilter.all
                            ? 'No messages yet — check back soon.'
                            : 'Nothing here yet.',
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _MessageCard(item: filtered[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.item});

  final MessageWithState item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatRelativeDate(item.message.createdAt), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            item.message.body,
            style: const TextStyle(fontSize: 15, height: 1.6, letterSpacing: 0.1, color: AppColors.nearBlack),
          ),
          const SizedBox(height: 8),
          MessageActionsRow(item: item),
        ],
      ),
    );
  }
}

/// Wraps content that isn't naturally scrollable (empty state, error text)
/// in something that still is, so pull-to-refresh keeps working.
class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
