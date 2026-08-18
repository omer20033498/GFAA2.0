/// The 5-point mood scale for check-ins. `level` (1-5) drives the trend
/// chart's bar height; `key` is what's stored in `checkins.mood` (matches
/// the Postgres check constraint in the migration).
enum Mood {
  struggling(key: 'struggling', emoji: '😞', label: 'Struggling', level: 1),
  low(key: 'low', emoji: '🙁', label: 'Low', level: 2),
  okay(key: 'okay', emoji: '😐', label: 'Okay', level: 3),
  good(key: 'good', emoji: '🙂', label: 'Good', level: 4),
  great(key: 'great', emoji: '😄', label: 'Great', level: 5);

  const Mood({required this.key, required this.emoji, required this.label, required this.level});

  final String key;
  final String emoji;
  final String label;
  final int level;

  static Mood fromKey(String key) => Mood.values.firstWhere((mood) => mood.key == key);
}
