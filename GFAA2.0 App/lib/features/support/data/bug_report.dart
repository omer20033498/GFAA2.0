enum BugReportStatus {
  open('open'),
  resolved('resolved');

  const BugReportStatus(this.key);

  final String key;

  static BugReportStatus fromKey(String key) => values.firstWhere((s) => s.key == key);
}

class BugReport {
  const BugReport({
    required this.id,
    required this.email,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  factory BugReport.fromMap(Map<String, dynamic> map) {
    return BugReport(
      id: map['id'] as String,
      email: map['email'] as String,
      body: map['body'] as String,
      status: BugReportStatus.fromKey(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String email;
  final String body;
  final BugReportStatus status;
  final DateTime createdAt;
}
