import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gfaa_logo.dart';
import '../application/auth_providers.dart';

/// Requests a password-reset email. Supabase always responds successfully
/// here regardless of whether the address has an account (avoids leaking
/// which emails are registered), so the UI shows the same "check your
/// email" confirmation either way.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) setState(() => _isSent = true);
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
      appBar: AppBar(),
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
                if (_isSent) ..._buildSentContent(textTheme) else ..._buildFormContent(textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent(TextTheme textTheme) {
    return [
      Text('Reset your password', style: textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text("Enter your email and we'll send you a link to reset it.", style: textTheme.bodyMedium),
      const SizedBox(height: 24),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
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
                  : const Text('Send reset link'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSentContent(TextTheme textTheme) {
    return [
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.softSage, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.deepGreen),
        ),
      ),
      const SizedBox(height: 20),
      Text('Check your email', style: textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        "We've sent a password reset link to ${_emailController.text.trim()}. Open it on this "
        'device to set a new password.',
        style: textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back to log in'),
      ),
    ];
  }
}
