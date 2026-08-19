import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/password_field.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/profile.dart';

class ProfileAccountScreen extends ConsumerWidget {
  const ProfileAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Account')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('$error'))),
          data: (profile) {
            if (profile == null) return const Center(child: Text('No profile found.'));
            return _ProfileAccountForm(profile: profile);
          },
        ),
      ),
    );
  }
}

class _ProfileAccountForm extends ConsumerStatefulWidget {
  const _ProfileAccountForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_ProfileAccountForm> createState() => _ProfileAccountFormState();
}

class _ProfileAccountFormState extends ConsumerState<_ProfileAccountForm> {
  late final _nameController = TextEditingController(text: widget.profile.effectiveDisplayName);
  late final _emailController = TextEditingController(text: widget.profile.email ?? '');
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isSavingName = false;
  bool _isSavingEmail = false;
  bool _isSavingPassword = false;
  bool _isDeleting = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a name');
      return;
    }
    setState(() {
      _isSavingName = true;
      _nameError = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateDisplayName(userId: widget.profile.id, displayName: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated.')));
      }
    } catch (error) {
      setState(() => _nameError = "Couldn't update: $error");
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _emailError = 'Enter a valid email');
      return;
    }
    setState(() {
      _isSavingEmail = true;
      _emailError = null;
    });
    try {
      await ref.read(authRepositoryProvider).updateEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your new inbox to confirm the email change.')),
        );
      }
    } catch (error) {
      setState(() => _emailError = "Couldn't update: $error");
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _isSavingPassword = true;
      _passwordError = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_newPasswordController.text);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
      }
    } catch (error) {
      setState(() => _passwordError = "Couldn't update: $error");
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account and everything in it — journal entries, check-ins, '
          "community posts, all of it. This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteOwnAccount();
      // The account is gone — sign out locally so `_AuthGate` returns to
      // the login screen rather than holding a session for a deleted user.
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't delete your account: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Name', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
        const SizedBox(height: 12),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Preferred name')),
        if (_nameError != null) ...[
          const SizedBox(height: 8),
          Text(_nameError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSavingName ? null : _saveName,
          child: _isSavingName
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save name'),
        ),
        const SizedBox(height: 28),
        Text('Email', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        if (_emailError != null) ...[
          const SizedBox(height: 8),
          Text(_emailError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSavingEmail ? null : _saveEmail,
          child: _isSavingEmail
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save email'),
        ),
        const SizedBox(height: 28),
        Text('Password', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
        const SizedBox(height: 12),
        Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _newPasswordController,
                labelText: 'New password',
                validator: (value) =>
                    (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirmPasswordController,
                labelText: 'Confirm new password',
                validator: (value) => value != _newPasswordController.text ? 'Passwords do not match' : null,
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 8),
                Text(_passwordError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSavingPassword ? null : _savePassword,
                child: _isSavingPassword
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save password'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text('Danger zone', style: textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        Text(
          'Deleting your account removes everything permanently — this cannot be undone.',
          style: textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: _isDeleting ? null : _confirmDelete,
          child: _isDeleting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Delete account'),
        ),
      ],
    );
  }
}
