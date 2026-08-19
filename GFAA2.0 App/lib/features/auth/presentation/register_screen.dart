import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/leaf_branch.dart';
import '../../../core/widgets/password_field.dart';
import '../application/auth_providers.dart';
import 'auth_field_style.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preferredNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _preferredNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
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
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            preferredName: _preferredNameController.text.trim(),
            fullName: _fullNameController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label — coming soon')));
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
                        child: accentHeadline('Create your account', 'account', textTheme.headlineMedium),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'A safe space to reflect, heal and find support.',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _preferredNameController,
                        decoration: authFieldDecoration(
                          icon: Icons.person_outline,
                          hint: 'Preferred name',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Enter a preferred name' : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4, left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "This is what we'll call you in the app.",
                            style: TextStyle(fontSize: 11.5, color: AppColors.nearBlack),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: authFieldDecoration(
                          icon: Icons.badge_outlined,
                          hint: 'Full name (optional)',
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          hint: 'Choose a password',
                          suffixIcon: base.suffixIcon,
                        ),
                        validator: (value) =>
                            (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _confirmController,
                        labelText: 'Confirm password',
                        decorationBuilder: (base) => authFieldDecoration(
                          icon: Icons.lock_outline,
                          hint: 'Confirm your password',
                          suffixIcon: base.suffixIcon,
                        ),
                        validator: (value) =>
                            value != _passwordController.text ? 'Passwords do not match' : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: textTheme.labelSmall,
                            children: [
                              const TextSpan(text: 'By creating an account, you agree to our '),
                              TextSpan(
                                text: 'Terms of Use',
                                style: const TextStyle(decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _comingSoon('Terms of Use'),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _comingSoon('Privacy Policy'),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            : const Text('Create account'),
                      ),
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
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const GoogleLogo(),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Already have an account? Log in'),
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
