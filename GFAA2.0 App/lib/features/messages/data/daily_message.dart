class DailyMessage {
  const DailyMessage({required this.id, required this.body, required this.createdAt});

  factory DailyMessage.fromMap(Map<String, dynamic> map) {
    return DailyMessage(
      id: map['id'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String body;
  final DateTime createdAt;
}
