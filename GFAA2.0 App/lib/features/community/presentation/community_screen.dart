import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../auth/application/auth_providers.dart';
import '../application/community_providers.dart';
import '../data/community_post.dart';
import 'community_compose_screen.dart';
import 'community_post_screen.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CommunityComposeScreen()),
    );
    if (posted != true || !context.mounted) return;
    final isAdmin = ref.read(profileProvider).value?.role == 'admin';
    // The Moderate Posts screen (a different screen, possibly not even
    // mounted right now) fetches rather than watching a live stream, so it
    // never learns about a post created from here on its own — an admin's
    // post lands straight in Approved, a user's in Pending, so invalidate
    // both rather than only whichever this author's role would produce.
    ref.invalidate(postsByStatusProvider(PostStatus.approved));
    ref.invalidate(postsByStatusProvider(PostStatus.pending));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isAdmin ? 'Posted.' : "Submitted — it'll appear once approved.")),
    );
  }

  Future<void> _deletePost(BuildContext context, WidgetRef ref, CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text("This removes it and all its comments. This can't be undone."),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete: $error")));
      }
    } finally {
      // The realtime feed stream doesn't reliably re-evict a row on DELETE
      // (same gap noted in CommunityRepository.fetchPostsByStatus's own
      // comment) -- invalidating forces an immediate fresh read for the
      // person who just deleted it, rather than waiting on a manual
      // refresh. Other viewers still get it live via the stream as normal.
      ref.invalidate(communityFeedProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);
    final isAdmin = ref.watch(profileProvider).value?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: AppColors.offWhite,
        onPressed: () => _compose(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('$error'))),
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No posts yet — be the first to share something.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(
                  post: post,
                  showDelete: isAdmin,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CommunityPostScreen(post: post)),
                  ),
                  onDelete: () => _deletePost(context, ref, post),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
  });

  final CommunityPost post;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.coolWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
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
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Text(
                  post.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ),
              if (showDelete)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.deepGreen),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
