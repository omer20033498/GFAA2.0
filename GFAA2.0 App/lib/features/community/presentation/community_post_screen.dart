import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../auth/application/auth_providers.dart';
import '../application/community_providers.dart';
import '../data/community_comment.dart';
import '../data/community_post.dart';

class CommunityPostScreen extends ConsumerStatefulWidget {
  const CommunityPostScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends ConsumerState<CommunityPostScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    final userId = ref.read(currentUserIdProvider);
    final profile = ref.read(profileProvider).value;
    if (userId == null || profile == null) return;

    setState(() => _isSending = true);
    try {
      await ref.read(communityRepositoryProvider).createComment(
            postId: widget.post.id,
            authorId: userId,
            authorDisplayName: profile.effectiveDisplayName,
            body: body,
          );
      _commentController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't reply: $error")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this reply?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityRepositoryProvider).deleteComment(comment.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete: $error")));
      }
    } finally {
      // Same realtime-doesn't-reliably-re-evict-on-DELETE gap as posts
      // (see invalidateAfterPostRemoved) — force a fresh read for whoever
      // just deleted it rather than waiting on a manual refresh. Deleting
      // a comment doesn't add anything new to the stream, so there's no
      // duplicate-on-insert risk here the way there is for posts.
      ref.invalidate(postCommentsProvider(widget.post.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAdmin = ref.watch(profileProvider).value?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.post.authorDisplayName,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.deepGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(formatRelativeDate(widget.post.createdAt), style: textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.post.body,
                    style: const TextStyle(fontSize: 16, height: 1.6, letterSpacing: 0.1, color: AppColors.nearBlack),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Text('$error'),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Text('No replies yet.', style: textTheme.bodyMedium);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final comment in comments)
                            _CommentTile(
                              comment: comment,
                              canDelete: isAdmin || comment.authorId == currentUserId,
                              onDelete: () => _deleteComment(comment),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(999)),
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Write a reply…',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.deepGreen),
                      icon: const Icon(Icons.arrow_upward, color: AppColors.offWhite),
                      onPressed: _isSending ? null : _sendComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.canDelete, required this.onDelete});

  final CommunityComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorDisplayName,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.deepGreen, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text('· ${formatRelativeDate(comment.createdAt)}', style: textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.deepGreen),
              onPressed: onDelete,
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
