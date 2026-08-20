import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../application/practitioner_providers.dart';
import '../data/csv_download/csv_download.dart';
import '../data/practitioner.dart';

class PractitionerReviewScreen extends ConsumerStatefulWidget {
  const PractitionerReviewScreen({super.key, this.initialTab = PractitionerStatus.pending});

  /// Lets a caller land directly on a specific tab — e.g. the Admin
  /// Dashboard's payment stat opens straight to Approved, since that's
  /// where an unpaid-but-approved listing actually lives.
  final PractitionerStatus initialTab;

  @override
  ConsumerState<PractitionerReviewScreen> createState() => _PractitionerReviewScreenState();
}

class _PractitionerReviewScreenState extends ConsumerState<PractitionerReviewScreen> {
  late PractitionerStatus _tab = widget.initialTab;

  /// A listing moves between tabs (e.g. pending -> approved), so every
  /// mutation invalidates all four lists rather than just the current one.
  void _refreshAll() {
    for (final status in PractitionerStatus.values) {
      ref.invalidate(practitionersByStatusProvider(status));
    }
  }

  Future<void> _approve(Practitioner practitioner) async {
    try {
      await ref
          .read(practitionerRepositoryProvider)
          .setStatus(id: practitioner.id, status: PractitionerStatus.approved);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't approve: $error")));
      }
    } finally {
      _refreshAll();
    }
  }

  Future<void> _reject(Practitioner practitioner) async {
    final confirmed = await _confirm(
      title: 'Reject this application?',
      content: "It won't be listed. The applicant will still see their application as rejected.",
      confirmLabel: 'Reject',
    );
    if (!confirmed) return;
    try {
      await ref
          .read(practitionerRepositoryProvider)
          .setStatus(id: practitioner.id, status: PractitionerStatus.rejected);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't reject: $error")));
      }
    } finally {
      _refreshAll();
    }
  }

  Future<void> _suspend(Practitioner practitioner) async {
    final confirmed = await _confirm(
      title: 'Suspend this listing?',
      content: 'Their listing comes down and their account reverts to a normal user.',
      confirmLabel: 'Suspend',
    );
    if (!confirmed) return;
    try {
      await ref
          .read(practitionerRepositoryProvider)
          .setStatus(id: practitioner.id, status: PractitionerStatus.suspended);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't suspend: $error")));
      }
    } finally {
      _refreshAll();
    }
  }

  Future<void> _reactivate(Practitioner practitioner) async {
    try {
      await ref
          .read(practitionerRepositoryProvider)
          .setStatus(id: practitioner.id, status: PractitionerStatus.approved);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't reactivate: $error")));
      }
    } finally {
      _refreshAll();
    }
  }

  Future<void> _delete(Practitioner practitioner) async {
    final confirmed = await _confirm(
      title: 'Remove this listing?',
      content:
          "This deletes it entirely, rather than just changing its status. Their account reverts to a normal "
          "user. This can't be undone.",
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;
    try {
      await ref.read(practitionerRepositoryProvider).deleteListing(practitioner.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't remove: $error")));
      }
    } finally {
      _refreshAll();
    }
  }

  /// On web, downloads a real `.csv` file straight to the browser's
  /// Downloads folder — no share-sheet detour. Elsewhere (Android/iOS),
  /// there's no browser to download through, so it shares the file instead,
  /// where "Save to Files" in the share sheet is the normal way to keep it.
  Future<void> _export() async {
    try {
      final practitioners = await ref.read(practitionerRepositoryProvider).fetchAll();
      final csv = _practitionersToCsv(practitioners);
      const filename = 'gfaa-practitioners.csv';
      if (downloadCsvInBrowser(csv, filename)) return;

      final file = XFile.fromData(utf8.encode(csv), mimeType: 'text/csv', name: filename);
      await SharePlus.instance.share(ShareParams(files: [file], fileNameOverrides: [filename]));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't export: $error")));
      }
    }
  }

  Future<bool> _confirm({required String title, required String content, required String confirmLabel}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel)),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final practitionersAsync = ref.watch(practitionersByStatusProvider(_tab));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practitioner Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export all',
            onPressed: _export,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: FilterTabs<PractitionerStatus>(
                options: PractitionerStatus.values,
                labelOf: (status) => status.label,
                selected: _tab,
                onChanged: (status) => setState(() => _tab = status),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(practitionersByStatusProvider(_tab).future),
                child: practitionersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ScrollableMessage(message: '$error'),
                  data: (practitioners) {
                    if (practitioners.isEmpty) {
                      return _ScrollableMessage(
                        message: switch (_tab) {
                          PractitionerStatus.pending => 'Nothing waiting on review.',
                          PractitionerStatus.approved => 'No approved practitioners yet.',
                          PractitionerStatus.rejected => 'No rejected applications.',
                          PractitionerStatus.suspended => 'No suspended listings.',
                        },
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: practitioners.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final practitioner = practitioners[index];
                        return _ReviewCard(
                          practitioner: practitioner,
                          onApprove: _tab == PractitionerStatus.pending ? () => _approve(practitioner) : null,
                          onReject: _tab == PractitionerStatus.pending ? () => _reject(practitioner) : null,
                          onSuspend: _tab == PractitionerStatus.approved ? () => _suspend(practitioner) : null,
                          onReactivate:
                              _tab == PractitionerStatus.suspended ? () => _reactivate(practitioner) : null,
                          onDelete: () => _delete(practitioner),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared as plain text (not a real .csv file attachment) — that needs a
/// temp-file + share step which isn't worth a new dependency (`path_provider`)
/// for an "if required" admin convenience. Whatever the admin shares it to
/// (email, notes, etc.) can be saved as .csv manually from there.
String _practitionersToCsv(List<Practitioner> practitioners) {
  String escape(String value) => '"${value.replaceAll('"', '""')}"';

  final header = [
    'Full name',
    'Email',
    'Phone',
    'Profession',
    'Qualifications',
    'Expertise',
    'State',
    'Location',
    'Delivery options',
    'Status',
    'Applied',
  ].map(escape).join(',');

  final rows = practitioners.map((practitioner) {
    return [
      practitioner.fullName,
      practitioner.email,
      practitioner.phone,
      practitioner.profession.label,
      practitioner.qualifications,
      practitioner.expertise ?? '',
      practitioner.state,
      practitioner.location,
      practitioner.deliveryOptions.map((option) => option.label).join('; '),
      practitioner.status.label,
      practitioner.createdAt.toIso8601String(),
    ].map(escape).join(',');
  });

  return ([header, ...rows]).join('\n');
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.practitioner,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onReactivate,
    required this.onDelete,
  });

  final Practitioner practitioner;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practitioner.fullName,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.deepGreen, fontWeight: FontWeight.w600),
                    ),
                    Text('${practitioner.profession.label} · ${practitioner.location}, ${practitioner.state}',
                        style: textTheme.bodyMedium),
                    Text(practitioner.email, style: textTheme.labelSmall),
                    Text(practitioner.qualifications, style: textTheme.labelSmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remove listing',
                onPressed: onDelete,
              ),
            ],
          ),
          if (onApprove != null && onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepGreen),
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(onPressed: onApprove, child: const Text('Approve')),
                ),
              ],
            ),
          ],
          if (onSuspend != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepGreen),
              onPressed: onSuspend,
              child: const Text('Suspend'),
            ),
          ],
          if (onReactivate != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onReactivate,
              child: const Text('Reactivate'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wraps content that isn't naturally scrollable (empty state, error text)
/// in something that still is, so pull-to-refresh keeps working.
class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
