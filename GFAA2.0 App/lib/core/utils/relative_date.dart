const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today" / "Yesterday" / "Aug 15" / "Aug 15, 2025" — no `intl` dependency
/// for a label this small.
String formatRelativeDate(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.toLocal();

  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  if (isSameDay(local, now)) return 'Today';
  if (isSameDay(local, now.subtract(const Duration(days: 1)))) return 'Yesterday';

  final monthLabel = '${_months[local.month - 1]} ${local.day}';
  return local.year == now.year ? monthLabel : '$monthLabel, ${local.year}';
}
