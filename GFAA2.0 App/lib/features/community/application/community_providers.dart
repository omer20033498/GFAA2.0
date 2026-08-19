import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/community_comment.dart';
import '../data/community_post.dart';
import '../data/community_repository.dart';

final communityRepositoryProvider = Provider((ref) => CommunityRepository());

final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).watchApprovedPosts();
});

final postsByStatusProvider = FutureProvider.family<List<CommunityPost>, PostStatus>((ref, status) {
  return ref.watch(communityRepositoryProvider).fetchPostsByStatus(status);
});

final postCommentsProvider = StreamProvider.family<List<CommunityComment>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).watchComments(postId);
});

/// Nudges the moderation queue's three per-status lists — always safe to
/// call after any post mutation, since it's a plain fetch with no realtime
/// subscription to conflict with.
void _invalidateModerationLists(WidgetRef ref) {
  for (final status in PostStatus.values) {
    ref.invalidate(postsByStatusProvider(status));
  }
}

/// Full sync after **removing or changing the status of** a post
/// (approve/reject/delete) — invalidates both the moderation lists above
/// and the realtime `communityFeedProvider`. The feed invalidation matters
/// here because its live stream doesn't reliably re-evict a row on
/// DELETE/UPDATE (see CommunityRepository.fetchPostsByStatus's comment).
///
/// **Do not use this after creating a post.** A fresh insert already
/// arrives through the feed's realtime subscription correctly — invalidating
/// the stream *as well*, right on top of that, races the still-settling
/// realtime event against a freshly torn-down-and-rebuilt stream and was
/// observed to show the new post twice. Use [invalidateAfterCreate] there
/// instead, which only refreshes the (non-realtime) moderation lists.
void invalidateAfterPostRemoved(WidgetRef ref) {
  ref.invalidate(communityFeedProvider);
  _invalidateModerationLists(ref);
}

/// Sync after **creating** a post — only the moderation lists, deliberately
/// leaving the realtime feed alone. See [invalidateAfterPostRemoved]'s doc
/// comment for why.
void invalidateAfterCreate(WidgetRef ref) => _invalidateModerationLists(ref);
