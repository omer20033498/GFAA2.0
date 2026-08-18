import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/message_providers.dart';
import '../data/message_with_state.dart';

/// Save/favourite/share icons for a message, wired straight to
/// [MessageRepository]. Shared by the full Daily Messages list and the
/// latest-message preview on Home, so the two don't drift.
class MessageActionsRow extends ConsumerWidget {
  const MessageActionsRow({super.key, required this.item});

  final MessageWithState item;

  Future<void> _setState(WidgetRef ref, BuildContext context, {bool? saved, bool? favourited}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      await ref.read(messageRepositoryProvider).setMessageState(
            userId: userId,
            messageId: item.message.id,
            saved: saved,
            favourited: favourited,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update: $error")));
      }
    } finally {
      ref.invalidate(messagesWithStateProvider);
    }
  }

  Future<void> _share(WidgetRef ref) async {
    await SharePlus.instance.share(ShareParams(text: item.message.body));
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    // Best-effort — a failure to record the share shouldn't surface as an
    // error, the share itself already succeeded.
    try {
      await ref.read(messageRepositoryProvider).setMessageState(
            userId: userId,
            messageId: item.message.id,
            markShared: true,
          );
    } catch (_) {
      // Ignored — see comment above.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: Icon(item.saved ? Icons.bookmark : Icons.bookmark_border, color: AppColors.deepGreen),
          onPressed: () => _setState(ref, context, saved: !item.saved),
          tooltip: item.saved ? 'Unsave' : 'Save',
        ),
        IconButton(
          icon: Icon(
            item.favourited ? Icons.favorite : Icons.favorite_border,
            color: item.favourited ? Colors.red.shade400 : AppColors.deepGreen,
          ),
          onPressed: () => _setState(ref, context, favourited: !item.favourited),
          tooltip: item.favourited ? 'Remove favourite' : 'Favourite',
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.deepGreen),
          onPressed: () => _share(ref),
          tooltip: 'Share',
        ),
      ],
    );
  }
}
