import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_date.dart';
import '../../auth/application/auth_providers.dart';
import '../application/checkin_providers.dart';
import '../data/checkin.dart';
import '../data/mood.dart';

class CheckinsScreen extends ConsumerStatefulWidget {
  const CheckinsScreen({super.key});

  @override
  ConsumerState<CheckinsScreen> createState() => _CheckinsScreenState();
}

class _CheckinsScreenState extends ConsumerState<CheckinsScreen> {
  Mood? _selectedMood;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mood = _selectedMood;
    final userId = ref.read(currentUserIdProvider);
    if (mood == null || userId == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(checkinRepositoryProvider).createCheckin(
            userId: userId,
            mood: mood,
            note: _noteController.text.trim(),
          );
      _noteController.clear();
      setState(() => _selectedMood = null);
      ref.invalidate(checkinsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't save: $error")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete(Checkin checkin) async {
    try {
      await ref.read(checkinRepositoryProvider).deleteCheckin(checkin.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete: $error")));
      }
    } finally {
      ref.invalidate(checkinsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkinsAsync = ref.watch(checkinsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-ins')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(checkinsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              _MoodPickerCard(
                selectedMood: _selectedMood,
                noteController: _noteController,
                isSaving: _isSaving,
                onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                onSave: _save,
              ),
              const SizedBox(height: 28),
              checkinsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('$error', textAlign: TextAlign.center),
                ),
                data: (checkins) {
                  if (checkins.isEmpty) return const _EmptyHistory();
                  final trend = checkins.take(7).toList().reversed.toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your trend', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
                      const SizedBox(height: 12),
                      _TrendChart(checkins: trend),
                      const SizedBox(height: 28),
                      Text('History', style: textTheme.titleMedium?.copyWith(color: AppColors.deepGreen)),
                      const SizedBox(height: 12),
                      for (final checkin in checkins) ...[
                        _CheckinHistoryTile(checkin: checkin, onDelete: () => _delete(checkin)),
                        const SizedBox(height: 8),
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

class _MoodPickerCard extends StatelessWidget {
  const _MoodPickerCard({
    required this.selectedMood,
    required this.noteController,
    required this.isSaving,
    required this.onMoodSelected,
    required this.onSave,
  });

  final Mood? selectedMood;
  final TextEditingController noteController;
  final bool isSaving;
  final ValueChanged<Mood> onMoodSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling right now?', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final mood in Mood.values)
                _MoodOption(
                  mood: mood,
                  selected: mood == selectedMood,
                  onTap: () => onMoodSelected(mood),
                ),
            ],
          ),
          if (selectedMood != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Add a note (optional)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save check-in'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({required this.mood, required this.selected, required this.onTap});

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.softSage : AppColors.offWhite,
          border: selected ? Border.all(color: AppColors.deepGreen, width: 2) : null,
        ),
        child: Text(mood.emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

/// A plain, hand-built bar row — the mood scale is 5 discrete levels, not
/// continuous numeric data, so a full charting package felt like overkill.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.checkins});

  /// Oldest first, newest last — already limited to the most recent 7.
  final List<Checkin> checkins;

  static const _maxBarHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    // No fixed-height SizedBox around this Row — letting it size to its
    // content avoids a repeat of the previous overflow, where a hardcoded
    // height budget came in a few pixels short of what the emoji + bar
    // actually needed. Exact dates are already visible in History below,
    // so there's no label under each bar to budget space for either.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final checkin in checkins)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(checkin.mood.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: _maxBarHeight * (checkin.mood.level / Mood.values.length),
                  decoration: BoxDecoration(
                    color: AppColors.sageGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CheckinHistoryTile extends StatelessWidget {
  const _CheckinHistoryTile({required this.checkin, required this.onDelete});

  final Checkin checkin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(checkin.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this check-in?'),
            content: const Text("This can't be undone."),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: AppColors.softSage, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: AppColors.deepGreen),
      ),
      child: Container(
        decoration: BoxDecoration(color: AppColors.coolWhite, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(checkin.mood.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatRelativeDate(checkin.createdAt), style: Theme.of(context).textTheme.labelSmall),
                  if (checkin.note != null && checkin.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(checkin.note!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        'Log your first check-in above to start seeing your trend here.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
