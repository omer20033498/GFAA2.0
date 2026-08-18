import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../auth/application/auth_providers.dart';
import '../application/message_providers.dart';
import '../data/daily_message.dart';

class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  final _bodyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    final adminId = ref.read(currentUserIdProvider);
    if (body.isEmpty || adminId == null) return;

    setState(() => _isSending = true);
    try {
      await ref.read(messageRepositoryProvider).sendMessage(adminId: adminId, body: body);
      _bodyController.clear();
      ref.invalidate(sentMessagesProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't send: $error")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _delete(DailyMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this message?'),
        content: const Text(
          "This removes it for every user — including anyone who's saved or favourited it. "
          "This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(messageRepositoryProvider).deleteMessage(message.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete: $error")));
      }
    } finally {
      ref.invalidate(sentMessagesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentAsync = ref.watch(sentMessagesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Messages')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(sentMessagesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: "Write today's message…"),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isSending ? null : _send,
                      child: _isSending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send to all users'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Sent', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
              const SizedBox(height: 12),
              sentAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('$error', textAlign: TextAlign.center),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        "You haven't sent any messages yet.",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final message in messages) ...[
                        _SentMessageTile(message: message, onDelete: () => _delete(message)),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SentMessageTile extends StatelessWidget {
  const _SentMessageTile({required this.message, required this.onDelete});

  final DailyMessage message;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatRelativeDate(message.createdAt), style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(message.body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.deepGreen),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
