import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../application/journal_providers.dart';
import '../data/journal_entry.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  /// Pushes the editor and refetches the list on return — the list has no
  /// realtime subscription (see journal_providers.dart), so this is what
  /// keeps it in sync with whatever the editor just did.
  Future<void> _openEntry(BuildContext context, WidgetRef ref, {JournalEntry? entry}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JournalEntryScreen(entry: entry)),
    );
    ref.invalidate(journalEntriesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: AppColors.offWhite,
        onPressed: () => _openEntry(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _JournalSubtitle(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(journalEntriesProvider.future),
                child: entriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ScrollableMessage(message: '$error'),
                  data: (entries) {
                    if (entries.isEmpty) return const _EmptyState();
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _JournalEntryCard(
                          entry: entry,
                          onTap: () => _openEntry(context, ref, entry: entry),
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

class _JournalSubtitle extends StatelessWidget {
  const _JournalSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'This is your safe space to express your thoughts and feelings.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.coolWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatRelativeDate(entry.createdAt),
                style: textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                entry.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 32),
          child: Column(
            children: [
              const Icon(Icons.edit_note, size: 40, color: AppColors.deepGreen),
              const SizedBox(height: 16),
              Text('Start your first entry', style: textTheme.headlineSmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}
