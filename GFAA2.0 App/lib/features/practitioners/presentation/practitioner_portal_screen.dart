import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/practitioner_providers.dart';
import '../data/delivery_option.dart';
import '../data/practitioner.dart';
import 'practitioner_listing_fields.dart';

class PractitionerPortalScreen extends ConsumerWidget {
  const PractitionerPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationAsync = ref.watch(myPractitionerApplicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practitioner Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: applicationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('$error'))),
          data: (practitioner) {
            if (practitioner == null) {
              // Shouldn't normally happen (an approved account implies an
              // approved application exists), but avoid a dead end if it does.
              return const Center(child: Text('No listing found.'));
            }
            return _PortalContent(practitioner: practitioner);
          },
        ),
      ),
    );
  }
}

class _PortalContent extends ConsumerStatefulWidget {
  const _PortalContent({required this.practitioner});

  final Practitioner practitioner;

  @override
  ConsumerState<_PortalContent> createState() => _PortalContentState();
}

class _PortalContentState extends ConsumerState<_PortalContent> {
  final _formKey = GlobalKey<FormState>();
  late final PractitionerFormController _listing;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  bool _isSavingEmail = false;
  String? _errorMessage;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    final practitioner = widget.practitioner;
    _listing = PractitionerFormController(
      fullName: practitioner.fullName,
      phone: practitioner.phone,
      profession: practitioner.profession,
      qualifications: practitioner.qualifications,
      expertise: practitioner.expertise ?? '',
      state: practitioner.state,
      location: practitioner.location,
      deliveryOptions: Set<DeliveryOption>.from(practitioner.deliveryOptions),
      website: practitioner.website ?? '',
    );
    _emailController = TextEditingController(text: practitioner.email);
  }

  @override
  void dispose() {
    _listing.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// The Subscribe button is real UI, not real Stripe -- there's no Stripe
  /// account yet (see CLAUDE.md finalised feature 8), so this just explains
  /// that rather than silently doing nothing. Swap this out for a real
  /// Checkout redirect once Stripe is wired up.
  void _subscribeComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payments aren't connected yet — this button will take you to Stripe once billing launches."),
      ),
    );
  }

  Future<void> _updateEmail() async {
    final newEmail = _emailController.text.trim();
    if (!newEmail.contains('@')) {
      setState(() => _emailError = 'Enter a valid email');
      return;
    }

    setState(() {
      _isSavingEmail = true;
      _emailError = null;
    });
    try {
      // Updates the public contact email shown in the directory immediately,
      // and separately kicks off Supabase's own confirmation flow for the
      // actual login email — that part only takes effect once the
      // confirmation link is opened, same as sign-up.
      await ref.read(practitionerRepositoryProvider).updateContactEmail(id: widget.practitioner.id, email: newEmail);
      await ref.read(authRepositoryProvider).updateEmail(newEmail);
      ref.invalidate(myPractitionerApplicationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact email updated. Check your new inbox to confirm the login email change.'),
          ),
        );
      }
    } catch (error) {
      setState(() => _emailError = "Couldn't update: $error");
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    final hasDeliveryOption = _listing.deliveryOptions.isNotEmpty;
    if (!formValid || !hasDeliveryOption) {
      setState(() {
        _errorMessage = !hasDeliveryOption ? 'Select at least one delivery option.' : null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(practitionerRepositoryProvider).updateListing(
            id: widget.practitioner.id,
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
      ref.invalidate(myPractitionerApplicationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated.')));
      }
    } catch (error) {
      setState(() => _errorMessage = "Couldn't save: $error");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Subscription', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.softSage, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.deepGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status: not active — billing hasn\'t launched yet. Your listing will go live once '
                      'subscription payments are set up; nothing to do on your end for now.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _subscribeComingSoon,
                child: const Text('Subscribe — \$10 AUD/month'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepGreen),
                      onPressed: null,
                      child: const Text('Update payment details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepGreen),
                      onPressed: null,
                      child: const Text('Cancel subscription'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Account email', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
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
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepGreen),
          onPressed: _isSavingEmail ? null : _updateEmail,
          child: _isSavingEmail
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Update email'),
        ),
        const SizedBox(height: 24),
        Text('Your listing', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PractitionerListingFields(controller: _listing, onChanged: () => setState(() {})),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
