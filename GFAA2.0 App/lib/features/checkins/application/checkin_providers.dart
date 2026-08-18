import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/checkin.dart';
import '../data/checkin_repository.dart';

final checkinRepositoryProvider = Provider((ref) => CheckinRepository());

/// A plain fetch, not realtime — see journal_providers.dart's
/// journalEntriesProvider for the same reasoning. Refreshed via
/// `ref.invalidate` after create/delete, and pull-to-refresh.
final checkinsProvider = FutureProvider<List<Checkin>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const []);
  return ref.watch(checkinRepositoryProvider).fetchCheckins(userId);
});
