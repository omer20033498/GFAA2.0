class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.totalPractitioners,
    required this.pendingPractitioners,
    required this.pendingPosts,
    required this.newUsersThisWeek,
    required this.checkinsThisWeek,
    required this.openBugReports,
  });

  factory AdminStats.fromMap(Map<String, dynamic> map) {
    int asInt(String key) => (map[key] as num).toInt();
    return AdminStats(
      totalUsers: asInt('total_users'),
      totalPractitioners: asInt('total_practitioners'),
      pendingPractitioners: asInt('pending_practitioners'),
      pendingPosts: asInt('pending_posts'),
      newUsersThisWeek: asInt('new_users_this_week'),
      checkinsThisWeek: asInt('checkins_this_week'),
      openBugReports: asInt('open_bug_reports'),
    );
  }

  final int totalUsers;
  final int totalPractitioners;
  final int pendingPractitioners;
  final int pendingPosts;
  final int newUsersThisWeek;
  final int checkinsThisWeek;
  final int openBugReports;
}
