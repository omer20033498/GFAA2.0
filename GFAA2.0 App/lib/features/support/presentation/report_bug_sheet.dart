import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/bug_report_providers.dart';

/// Opened from the profile drawer's "Report a Bug" row as a modal sheet
/// (not a full screen push), matching the reference design.
Future<void> showReportBugSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.offWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ReportBugSheet(),
  );
}

class _ReportBugSheet extends ConsumerStatefulWidget {
  const _ReportBugSheet();

  @override
  ConsumerState<_ReportBugSheet> createState() => _ReportBugSheetState();
}

class _ReportBugSheetState extends ConsumerState<_ReportBugSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  late final _emailController = TextEditingController(
    text: ref.read(profileProvider).value?.email ?? '',
  );
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bodyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(bugReportRepositoryProvider).submit(
            userId: userId,
            email: _emailController.text.trim(),
            body: _bodyController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thanks — we've got it and will follow up if needed.")),
        );
      }
    } catch (error) {
      setState(() => _errorMessage = "Couldn't send that: $error");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Report a bug', style: textTheme.headlineSmall)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Have you spotted a bug or error in the app? We would love to '
              'hear about it so we can fix it as soon as possible.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Report a bug...'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Tell us what happened' : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Please provide a contact email so we can follow up with you on this issue.',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _send,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send to GFAA'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
