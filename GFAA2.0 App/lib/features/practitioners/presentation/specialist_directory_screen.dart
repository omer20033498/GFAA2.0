import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../application/practitioner_providers.dart';
import '../australian_states.dart';
import '../data/delivery_option.dart';
import '../data/practitioner.dart';
import '../data/profession.dart';
import 'specialist_filter.dart';

class SpecialistDirectoryScreen extends ConsumerStatefulWidget {
  const SpecialistDirectoryScreen({super.key});

  @override
  ConsumerState<SpecialistDirectoryScreen> createState() => _SpecialistDirectoryScreenState();
}

class _SpecialistDirectoryScreenState extends ConsumerState<SpecialistDirectoryScreen> {
  String _query = '';
  String? _state;
  Profession? _profession;
  final Set<DeliveryOption> _deliveryOptions = {};

  @override
  Widget build(BuildContext context) {
    final directoryAsync = ref.watch(specialistDirectoryProvider);
    final filter = SpecialistFilter(
      query: _query,
      state: _state,
      profession: _profession,
      deliveryOptions: _deliveryOptions,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Specialist')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(specialistDirectoryProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Search by name, profession, expertise…'),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _state,
                      decoration: const InputDecoration(labelText: 'State'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final state in australianStates) DropdownMenuItem(value: state, child: Text(state)),
                      ],
                      onChanged: (value) => setState(() => _state = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Profession?>(
                      initialValue: _profession,
                      decoration: const InputDecoration(labelText: 'Profession'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final profession in Profession.values)
                          DropdownMenuItem(value: profession, child: Text(profession.label)),
                      ],
                      onChanged: (value) => setState(() => _profession = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in DeliveryOption.values)
                    FilterChip(
                      label: Text(option.label),
                      selected: _deliveryOptions.contains(option),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _deliveryOptions.add(option);
                        } else {
                          _deliveryOptions.remove(option);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              directoryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('$error', textAlign: TextAlign.center),
                ),
                data: (practitioners) {
                  final filtered = applySpecialistFilter(practitioners, filter);
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        practitioners.isEmpty
                            ? 'No listed specialists yet. Check back soon.'
                            : 'No specialists match those filters.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final practitioner in filtered) ...[
                        _SpecialistCard(practitioner: practitioner),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({required this.practitioner});

  final Practitioner practitioner;

  Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open that.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            practitioner.fullName,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.deepGreen, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text('${practitioner.profession.label} · ${practitioner.location}, ${practitioner.state}',
              style: textTheme.bodyMedium),
          Text(practitioner.qualifications, style: textTheme.labelSmall),
          if (practitioner.expertise != null && practitioner.expertise!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(practitioner.expertise!, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final option in practitioner.deliveryOptions)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.softSage, borderRadius: BorderRadius.circular(999)),
                  child: Text(option.label, style: const TextStyle(fontSize: 11, color: AppColors.deepGreen)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.call_outlined, size: 20, color: AppColors.deepGreen),
                tooltip: practitioner.phone,
                onPressed: () => _launch(context, Uri(scheme: 'tel', path: practitioner.phone)),
              ),
              IconButton(
                icon: const Icon(Icons.email_outlined, size: 20, color: AppColors.deepGreen),
                tooltip: practitioner.email,
                onPressed: () => _launch(context, Uri(scheme: 'mailto', path: practitioner.email)),
              ),
              if (practitioner.website != null && practitioner.website!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.public, size: 20, color: AppColors.deepGreen),
                  tooltip: practitioner.website,
                  onPressed: () => _launch(context, Uri.parse(practitioner.website!)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
