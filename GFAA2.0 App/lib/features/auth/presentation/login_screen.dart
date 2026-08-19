import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/leaf_branch.dart';
import '../../../core/widgets/password_field.dart';
import '../../practitioners/application/practitioner_providers.dart';
import '../../practitioners/presentation/practitioner_application_screen.dart';
import '../application/auth_providers.dart';
import 'auth_field_style.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Which "Register" leads to. Routing after a *successful* sign-in is still
/// always driven by the account's real `profiles.role` (see `_AuthGate`),
/// not this tab — but [_LoginScreenState._submit] does reject a sign-in
/// upfront when the account clearly belongs to the other audience (e.g. an
/// approved practitioner trying the User tab), rather than letting them in
/// and routing them away.
enum _LoginAudience {
  user('User'),
  practitioner('Practitioner');

  const _LoginAudience(this.label);

  final String label;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _errorMessage;
  _LoginAudience _audience = _LoginAudience.user;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final authRepository = ref.read(authRepositoryProvider);
    try {
      await authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = authRepository.currentUser?.id;
      if (userId == null) return;

      final profile = await ref.read(profileRepositoryProvider).fetchProfile(userId);
      final isPractitioner = profile?.role == 'practitioner';
      // A pending/rejected/suspended applicant hasn't been promoted to the
      // `practitioner` role yet, but they still belong on the Practitioner
      // tab (that's how they check their application status) — so "has
      // practitioner history" is broader than just the role check.
      final application = await ref.read(practitionerRepositoryProvider).fetchMyApplication(userId);
      final hasPractitionerHistory = isPractitioner || application != null;

      String? mismatch;
      if (_audience == _LoginAudience.user && isPractitioner) {
        mismatch = "This account is registered as a practitioner. Switch to the Practitioner tab to log in.";
      } else if (_audience == _LoginAudience.practitioner && !hasPractitionerHistory) {
        mismatch = "This account isn't registered as a practitioner.";
      }

      if (mismatch != null) {
        await authRepository.signOut();
        setState(() => _errorMessage = mismatch);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Just launches the browser — success/failure of the sign-in itself
  /// arrives later as an auth-state event once Google redirects back (see
  /// [AuthRepository.signInWithGoogle]), which `_AuthGate` reacts to on its
  /// own. Nothing to do here afterward, only report if the browser itself
  /// couldn't be launched.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: GfaaLogo()),
                      const SizedBox(height: 28),
                      Center(
                        child: FilterTabs<_LoginAudience>(
                          options: _LoginAudience.values,
                          labelOf: (audience) => audience.label,
                          selected: _audience,
                          onChanged: (audience) => setState(() => _audience = audience),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: accentHeadline('Log in to your account', 'account', textTheme.headlineMedium),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Welcome back. We're here when you need us.",
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: authFieldDecoration(icon: Icons.mail_outline, hint: 'Email address'),
                        validator: (value) =>
                            (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _passwordController,
                        labelText: 'Password',
                        decorationBuilder: (base) => authFieldDecoration(
                          icon: Icons.lock_outline,
                          hint: 'Password',
                          suffixIcon: base.suffixIcon,
                        ),
                        validator: (value) =>
                            (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.offWhite),
                              )
                            : const Text('Log in'),
                      ),
                      if (_audience == _LoginAudience.user) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or continue with', style: textTheme.labelSmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.nearBlack.withValues(alpha: 0.12)),
                          ),
                          onPressed: _isGoogleSubmitting ? null : _signInWithGoogle,
                          icon: _isGoogleSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const GoogleLogo(),
                          label: const Text('Continue with Google'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _audience == _LoginAudience.practitioner
                                  ? const PractitionerApplicationScreen()
                                  : const RegisterScreen(),
                            ),
                          ),
                          child: Text(
                            _audience == _LoginAudience.practitioner
                                ? "Don't have an account? Apply to be listed"
                                : "Don't have an account? Sign up",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(bottom: 0, left: -16, child: LeafBranch(width: 130, height: 60)),
            const Positioned(bottom: 0, right: -16, child: LeafBranch(width: 130, height: 60, mirrored: true)),
          ],
        ),
      ),
    );
  }
}
