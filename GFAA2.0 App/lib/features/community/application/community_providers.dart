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
