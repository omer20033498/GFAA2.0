import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../application/auth_providers.dart';

/// Shown when the app is reopened via the password-reset email link — see
/// `_AuthGate` in app.dart, which routes here on
/// `AuthChangeEvent.passwordRecovery` regardless of the normal auth/role
/// routing. Not reachable any other way.
///
/// After a successful update, this stays on a confirmation view rather than
/// navigating anywhere itself — signing out (below) flips the auth state,
/// which `_AuthGate` reacts to on its own by swapping back to `LoginScreen`.
/// Navigating manually here would race that automatic swap.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _isUpdated = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_passwordController.text);
      if (mounted) setState(() => _isUpdated = true);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: GfaaLogo()),
                const SizedBox(height: 32),
                if (_isUpdated) ..._buildUpdatedContent(textTheme) else ..._buildFormContent(textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent(TextTheme textTheme) {
    return [
      Text('Set a new password', style: textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text('Choose a new password for your account.', style: textTheme.bodyMedium),
      const SizedBox(height: 24),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) =>
                  (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
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
                  : const Text('Save new password'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildUpdatedContent(TextTheme textTheme) {
    return [
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, size: 40, color: AppColors.deepGreen),
        ),
      ),
      const SizedBox(height: 20),
      Text('Password updated', style: textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        'Log in with your new password to continue.',
        style: textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => ref.read(authRepositoryProvider).signOut(),
        child: const Text('Continue to log in'),
      ),
    ];
  }
}
