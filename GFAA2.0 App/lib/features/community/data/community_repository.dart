import '../../../core/supabase/supabase_client.dart';
import 'community_comment.dart';
import 'community_post.dart';

class CommunityRepository {
  /// Realtime — this is the one genuinely multi-user, collaborative feed
  /// in the app (unlike journal/check-ins/messages), so a live subscription
  /// actually earns its keep here.
  Stream<List<CommunityPost>> watchApprovedPosts() {
    return supabase
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .map((rows) => rows.map(CommunityPost.fromMap).toList());
  }

  /// A plain fetch, not realtime — unlike the main feed, this is a
  /// single-admin work queue, and a filtered realtime `.stream()` doesn't
  /// reliably re-evict a row once an UPDATE moves it out of the filter
  /// (e.g. approving a pending post) — it can keep showing the stale
  /// pre-update row. The screen invalidates this explicitly after every
  /// approve/reject/delete instead. Pending is oldest-first (FIFO, so
  /// nothing sits forever); approved/rejected history is newest-first.
  Future<List<CommunityPost>> fetchPostsByStatus(PostStatus status) async {
    final rows = await supabase
        .from('community_posts')
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: status == PostStatus.pending);
    return rows.map(CommunityPost.fromMap).toList();
  }

  Stream<List<CommunityComment>> watchComments(String postId) {
    return supabase
        .from('community_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .map((rows) => rows.map(CommunityComment.fromMap).toList());
  }

  /// The actual `status` this ends up with is enforced server-side by a
  /// trigger based on the caller's role (see migration 0007) — the client
  /// has no say in it regardless of what's passed here.
  Future<void> createPost({
    required String authorId,
    required String authorDisplayName,
    required String body,
  }) {
    return supabase.from('community_posts').insert({
      'author_id': authorId,
      'author_display_name': authorDisplayName,
      'body': body,
    });
  }

  Future<void> createComment({
    required String postId,
    required String authorId,
    required String authorDisplayName,
    required String body,
  }) {
    return supabase.from('community_comments').insert({
      'post_id': postId,
      'author_id': authorId,
      'author_display_name': authorDisplayName,
      'body': body,
    });
  }

  /// Admin-only (enforced by RLS). See journal/checkins/messages
  /// repositories for why `.select()` matters here.
  Future<void> setPostStatus({required String id, required PostStatus status}) async {
    final updated = await supabase
        .from('community_posts')
        .update({'status': status.name})
        .eq('id', id)
        .select();
    if (updated.isEmpty) {
      throw StateError("Couldn't find that post to update.");
    }
  }

  /// Admin-only (enforced by RLS) — deletes any post, cascading to its
  /// comments.
  Future<void> deletePost(String id) async {
    final deleted = await supabase.from('community_posts').delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw StateError("Couldn't find that post to delete.");
    }
  }

  /// Allowed for the comment's own author or an admin (enforced by RLS).
  Future<void> deleteComment(String id) async {
    final deleted = await supabase.from('community_comments').delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw StateError("Couldn't find that comment to delete.");
    }
  }
}
