import 'package:flutter/material.dart';

import '../australian_states.dart';
import '../data/delivery_option.dart';
import '../data/profession.dart';

/// Holds the controllers/state for the fields shared by the practitioner
/// application form and the portal's "edit my listing" form, so neither
/// screen has to duplicate ~9 fields. The owning screen creates one of
/// these, must call [dispose], and re-renders [PractitionerListingFields]
/// on selection changes (dropdown/chips aren't self-contained the way a
/// TextEditingController is).
class PractitionerFormController {
  PractitionerFormController({
    String fullName = '',
    String phone = '',
    this.profession = Profession.psychologist,
    String qualifications = '',
    String expertise = '',
    this.state,
    String location = '',
    Set<DeliveryOption>? deliveryOptions,
    String website = '',
  })  : fullNameController = TextEditingController(text: fullName),
        phoneController = TextEditingController(text: phone),
        qualificationsController = TextEditingController(text: qualifications),
        expertiseController = TextEditingController(text: expertise),
        locationController = TextEditingController(text: location),
        websiteController = TextEditingController(text: website),
        deliveryOptions = deliveryOptions ?? {};

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  Profession profession;
  final TextEditingController qualificationsController;
  final TextEditingController expertiseController;
  String? state;
  final TextEditingController locationController;
  final Set<DeliveryOption> deliveryOptions;
  final TextEditingController websiteController;

  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    qualificationsController.dispose();
    expertiseController.dispose();
    locationController.dispose();
    websiteController.dispose();
  }
}

class PractitionerListingFields extends StatelessWidget {
  const PractitionerListingFields({super.key, required this.controller, required this.onChanged});

  final PractitionerFormController controller;

  /// Called after a dropdown or delivery-option chip changes, so the owning
  /// screen can `setState` — text fields don't need this.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.fullNameController,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your full name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a phone number' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Profession>(
          initialValue: controller.profession,
          decoration: const InputDecoration(labelText: 'Profession'),
          items: [
            for (final profession in Profession.values)
              DropdownMenuItem(value: profession, child: Text(profession.label)),
          ],
          onChanged: (value) {
            if (value != null) controller.profession = value;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.qualificationsController,
          decoration: const InputDecoration(labelText: 'Qualifications'),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your qualifications' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.expertiseController,
          decoration: const InputDecoration(labelText: 'Area of grief expertise (optional)'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: controller.state,
          decoration: const InputDecoration(labelText: 'State'),
          items: [
            for (final state in australianStates) DropdownMenuItem(value: state, child: Text(state)),
          ],
          validator: (value) => value == null ? 'Select a state' : null,
          onChanged: (value) {
            controller.state = value;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.locationController,
          decoration: const InputDecoration(labelText: 'Location (suburb/city)'),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your location' : null,
        ),
        const SizedBox(height: 12),
        Text('Delivery options', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final option in DeliveryOption.values)
              FilterChip(
                label: Text(option.label),
                selected: controller.deliveryOptions.contains(option),
                onSelected: (selected) {
                  if (selected) {
                    controller.deliveryOptions.add(option);
                  } else {
                    controller.deliveryOptions.remove(option);
                  }
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.websiteController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Website (optional)'),
        ),
      ],
    );
  }
}
