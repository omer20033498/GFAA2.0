import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/filter_tabs.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../../practitioners/application/practitioner_providers.dart';
import '../../practitioners/presentation/practitioner_application_screen.dart';
import '../application/auth_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: GfaaLogo()),
                  const SizedBox(height: 32),
                  Center(
                    child: FilterTabs<_LoginAudience>(
                      options: _LoginAudience.values,
                      labelOf: (audience) => audience.label,
                      selected: _audience,
                      onChanged: (audience) => setState(() => _audience = audience),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
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
                          : "Don't have an account? Register",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
