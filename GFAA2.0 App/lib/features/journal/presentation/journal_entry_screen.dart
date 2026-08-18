import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../auth/application/auth_providers.dart';
import '../application/journal_providers.dart';
import '../data/journal_entry.dart';

enum _LeaveAction { discard, save }

/// Pass [entry] to edit an existing entry, or omit it to write a new one.
///
/// Saving is always an explicit action — the checkmark, or "Save" from the
/// leave-confirmation dialog. Nothing saves silently: leaving with no
/// changes just leaves, and leaving with unsaved changes always asks first.
class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key, this.entry});

  final JournalEntry? entry;

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  late final TextEditingController _controller;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry?.body ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final body = _controller.text.trim();
    if (body.isEmpty) return false;
    return body != (widget.entry?.body ?? '');
  }

  Future<bool> _save() async {
    final body = _controller.text.trim();
    final entry = widget.entry;

    setState(() => _isBusy = true);
    try {
      final repository = ref.read(journalRepositoryProvider);
      if (entry == null) {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) throw StateError('Not signed in.');
        await repository.createEntry(userId: userId, body: body);
      } else {
        await repository.updateEntry(id: entry.id, body: body);
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save: $error")),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// The checkmark: tapping it is an unambiguous "save this" — no dialog,
  /// just save and close. If there's nothing to save, it just closes.
  Future<void> _handleSaveAndClose() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final saved = await _save();
    if (saved && mounted) Navigator.of(context).pop();
  }

  /// The back button/gesture: leaving is ambiguous when there are unsaved
  /// changes, so this asks first rather than guessing. Nothing to save?
  /// Just leaves, no dialog.
  Future<void> _handleBack() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save this entry?'),
        content: const Text("You've made changes that haven't been saved yet."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveAction.discard),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (action == _LeaveAction.discard) {
      if (mounted) Navigator.of(context).pop();
    } else if (action == _LeaveAction.save) {
      final saved = await _save();
      if (saved && mounted) Navigator.of(context).pop();
    }
    // action == null (dialog dismissed without a choice): stay put.
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(journalRepositoryProvider).deleteEntry(entry.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't delete: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isBusy ? null : _handleBack,
          ),
          title: Text(
            entry == null ? 'New entry' : formatRelativeDate(entry.createdAt),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            if (entry != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _isBusy ? null : _delete,
              ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isBusy ? null : _handleSaveAndClose,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: TextField(
              controller: _controller,
              autofocus: entry == null,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 17,
                height: 1.8,
                letterSpacing: 0.1,
                color: AppColors.nearBlack,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                hintText: "Write what's on your mind...",
              ),
            ),
          ),
        ),
      ),
    );
  }
}
