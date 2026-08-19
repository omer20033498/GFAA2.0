import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/gfaa_logo.dart';
import '../../auth/presentation/verify_email_screen.dart';
import '../application/practitioner_providers.dart';
import 'practitioner_listing_fields.dart';

class PractitionerApplicationScreen extends ConsumerStatefulWidget {
  const PractitionerApplicationScreen({super.key});

  @override
  ConsumerState<PractitionerApplicationScreen> createState() => _PractitionerApplicationScreenState();
}

class _PractitionerApplicationScreenState extends ConsumerState<PractitionerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _listing = PractitionerFormController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _listing.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final hasDeliveryOption = _listing.deliveryOptions.isNotEmpty;
    if (!formValid || !hasDeliveryOption) {
      setState(() {
        _errorMessage = !hasDeliveryOption ? 'Select at least one delivery option.' : null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(practitionerRepositoryProvider).applyAsPractitioner(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _listing.fullNameController.text.trim(),
            phone: _listing.phoneController.text.trim(),
            profession: _listing.profession,
            qualifications: _listing.qualificationsController.text.trim(),
            expertise: _listing.expertiseController.text.trim(),
            state: _listing.state!,
            location: _listing.locationController.text.trim(),
            deliveryOptions: _listing.deliveryOptions.toList(),
            website: _listing.websiteController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
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
                  Text('Apply to be listed', style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Tell us about your practice. We'll review your application before it goes live.",
                    style: textTheme.bodyMedium,
                  ),
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
                  const SizedBox(height: 12),
                  PractitionerListingFields(controller: _listing, onChanged: () => setState(() {})),
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
                        : const Text('Submit application'),
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
