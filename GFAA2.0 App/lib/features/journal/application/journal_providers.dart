import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/journal_entry.dart';
import '../data/journal_repository.dart';

final journalRepositoryProvider = Provider((ref) => JournalRepository());

/// A plain fetch, not a realtime subscription — journal entries are
/// single-user, private data with no live/collaborative use case, so there's
/// no need for the extra moving part of a long-lived stream. The list screen
/// re-fetches (`ref.invalidate`) whenever it returns from the entry editor,
/// and via pull-to-refresh.
final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const []);
  return ref.watch(journalRepositoryProvider).fetchEntries(userId);
});
