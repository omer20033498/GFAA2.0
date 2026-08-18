enum PostStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const PostStatus(this.label);

  final String label;

  static PostStatus fromKey(String key) => PostStatus.values.byName(key);
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorDisplayName,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      authorDisplayName: map['author_display_name'] as String,
      body: map['body'] as String,
      status: PostStatus.fromKey(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String authorId;
  final String authorDisplayName;
  final String body;
  final PostStatus status;
  final DateTime createdAt;
}
