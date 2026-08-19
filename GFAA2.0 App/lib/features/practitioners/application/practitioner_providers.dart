import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/practitioner.dart';
import '../data/practitioner_repository.dart';

final practitionerRepositoryProvider = Provider((ref) {
  return PractitionerRepository(ref.watch(authRepositoryProvider));
});

/// Public directory (approved + paid listings only).
final specialistDirectoryProvider = FutureProvider<List<Practitioner>>((ref) {
  return ref.watch(practitionerRepositoryProvider).fetchDirectory();
});

/// This account's own application, at whatever status it's at — null if it
/// never applied. Used both for routing (see `_AuthGate`) and for the
/// Practitioner Portal / directory's "you've already applied" state.
final myPractitionerApplicationProvider = FutureProvider<Practitioner?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  return ref.watch(practitionerRepositoryProvider).fetchMyApplication(userId);
});

/// Admin moderation queue, one status at a time.
final practitionersByStatusProvider = FutureProvider.family<List<Practitioner>, PractitionerStatus>((ref, status) {
  return ref.watch(practitionerRepositoryProvider).fetchByStatus(status);
});
