import '../../../core/supabase/supabase_client.dart';
import 'profile.dart';

class ProfileRepository {
  /// Emits `null` until the `handle_new_user` trigger's row becomes visible
  /// (there's a brief window right after sign-up where the initial snapshot
  /// arrives before that insert), then the profile itself.
  Stream<Profile?> watchProfile(String userId) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : Profile.fromMap(rows.first));
  }

  /// One-off read (not a stream) — used right after sign-in, where the
  /// login screen needs an immediate answer for the audience-mismatch
  /// check rather than waiting on a provider.
  Future<Profile?> fetchProfile(String userId) async {
    final rows = await supabase.from('profiles').select().eq('id', userId).limit(1);
    if (rows.isEmpty) return null;
    return Profile.fromMap(rows.first);
  }

  Future<void> saveOnboardingAnswers(
    String userId,
    Map<String, dynamic> answers,
  ) {
    return supabase
        .from('profiles')
        .update({'onboarding_answers': answers})
        .eq('id', userId);
  }
}
