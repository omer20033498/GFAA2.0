import 'mood.dart';

class Checkin {
  const Checkin({
    required this.id,
    required this.userId,
    required this.mood,
    required this.note,
    required this.createdAt,
  });

  factory Checkin.fromMap(Map<String, dynamic> map) {
    return Checkin(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      mood: Mood.fromKey(map['mood'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final Mood mood;
  final String? note;
  final DateTime createdAt;
}
