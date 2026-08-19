import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../application/community_providers.dart';
import '../data/community_post.dart';

class CommunityModerationScreen extends ConsumerStatefulWidget {
  const CommunityModerationScreen({super.key});

  @override
  ConsumerState<CommunityModerationScreen> createState() => _CommunityModerationScreenState();
}

class _CommunityModerationScreenState extends ConsumerState<CommunityModerationScreen> {
  PostStatus _tab = PostStatus.pending;

  Future<void> _approve(CommunityPost post) async {
    try {
      await ref.read(communityRepositoryProvider).setPostStatus(id: post.id, status: PostStatus.approved);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't approve: $error")));
      }
    } finally {
      // Approving moves a post *into* the feed's realtime filter, same
      // shape as a fresh create — its live stream picks that up on its
      // own, so this only needs to refresh the moderation lists (see
      // invalidateAfterCreate's doc comment for why invalidating the feed
      // too would risk showing it twice).
      invalidateAfterCreate(ref);
    }
  }

  Future<void> _reject(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this post?'),
        content: const Text("It won't appear in the community feed. The author will still see it as rejected."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityRepositoryProvider).setPostStatus(id: post.id, status: PostStatus.rejected);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't reject: $error")));
      }
    } finally {
      // Rejecting only ever happens from Pending, which was never in the
      // feed to begin with, but invalidating it too is a harmless no-op
      // refresh (nothing new enters, so no duplicate risk) — kept for
      // consistency in case that ever changes.
      invalidateAfterPostRemoved(ref);
    }
  }

  Future<void> _delete(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text("This removes it entirely. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityRepositoryProvider).deletePost(post.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete: $error")));
      }
    } finally {
      // A delete can remove a post that was visible in the feed (if it was
      // approved), so the feed needs invalidating too, not just the
      // moderation lists.
      invalidateAfterPostRemoved(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsByStatusProvider(_tab));

    return Scaffold(
      appBar: AppBar(title: const Text('Moderate Posts')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: FilterTabs<PostStatus>(
                options: PostStatus.values,
                labelOf: (status) => status.label,
                selected: _tab,
                onChanged: (status) => setState(() => _tab = status),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(postsByStatusProvider(_tab).future),
                child: postsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ScrollableMessage(message: '$error'),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return _ScrollableMessage(
                        message: switch (_tab) {
                          PostStatus.pending => 'Nothing waiting on review.',
                          PostStatus.approved => 'No approved posts yet.',
                          PostStatus.rejected => 'No rejected posts.',
                        },
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: posts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _ModerationPostCard(
                          post: post,
                          onApprove: _tab == PostStatus.pending ? () => _approve(post) : null,
                          onReject: _tab == PostStatus.pending ? () => _reject(post) : null,
                          onDelete: () => _delete(post),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationPostCard extends StatelessWidget {
  const _ModerationPostCard({
    required this.post,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final CommunityPost post;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.authorDisplayName,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.deepGreen, fontWeight: FontWeight.w600),
                ),
              ),
              Text(formatRelativeDate(post.createdAt), style: textTheme.labelSmall),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.deepGreen),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
          Text(post.body, style: textTheme.bodyMedium),
          if (onApprove != null && onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepGreen),
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
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
