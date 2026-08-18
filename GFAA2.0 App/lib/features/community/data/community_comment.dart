class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorDisplayName,
    required this.body,
    required this.createdAt,
  });

  factory CommunityComment.fromMap(Map<String, dynamic> map) {
    return CommunityComment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      authorId: map['author_id'] as String,
      authorDisplayName: map['author_display_name'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String postId;
  final String authorId;
  final String authorDisplayName;
  final String body;
  final DateTime createdAt;
}
