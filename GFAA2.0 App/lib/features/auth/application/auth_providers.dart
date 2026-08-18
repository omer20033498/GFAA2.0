import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/profile.dart';
import '../data/profile_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The current session's user id, or null when signed out. Derives from
/// [authStateChangesProvider] so it updates immediately on sign in/out.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState?.session?.user.id;
});

final profileProvider = StreamProvider<Profile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(userId);
});
