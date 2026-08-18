import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

/// Deep link the app registers on both platforms (see AndroidManifest.xml /
/// Info.plist) to catch Supabase's password-recovery email link and reopen
/// straight to the reset-password screen.
const resetPasswordRedirectUrl = 'au.org.grieffirstaid.gfaa://reset-password';

class AuthRepository {
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  /// [preferredName] is required and becomes `profiles.display_name` (shown
  /// anywhere the app displays the user's name). [fullName] is optional and
  /// stored as `profiles.full_name` for records only.
  Future<void> signUp({
    required String email,
    required String password,
    required String preferredName,
    String? fullName,
  }) {
    return supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': preferredName,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      },
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return supabase.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: resetPasswordRedirectUrl,
    );
  }

  /// Only valid while the session is in `AuthChangeEvent.passwordRecovery`
  /// state, i.e. right after the user opens the reset-password email link.
  Future<void> updatePassword(String newPassword) {
    return supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
