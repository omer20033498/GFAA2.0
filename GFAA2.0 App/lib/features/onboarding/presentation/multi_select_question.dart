import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/selectable_option_card.dart';

class MultiSelectQuestion extends StatelessWidget {
  const MultiSelectQuestion({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accentWord,
  });

  final String question;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// A single word/phrase within [question] to highlight with the brand's
  /// neon accent, per the style guide: used sparingly, never as a fill or
  /// button colour. Must appear verbatim in [question] or it's ignored.
  final String? accentWord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionText(context),
        const SizedBox(height: 20),
        for (final option in options)
          SelectableOptionCard(
            label: option,
            selected: selected.contains(option),
            onTap: () {
              final next = Set<String>.from(selected);
              if (!next.remove(option)) next.add(option);
              onChanged(next);
            },
          ),
      ],
    );
  }

  Widget _buildQuestionText(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall;
    final word = accentWord;
    if (word == null || !question.contains(word)) {
      return Text(question, style: style);
    }
    final index = question.indexOf(word);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: question.substring(0, index)),
          TextSpan(
            text: word,
            style: const TextStyle(
              backgroundColor: AppColors.neonYellow,
              color: AppColors.nearBlack,
            ),
          ),
          TextSpan(text: question.substring(index + word.length)),
        ],
      ),
    );
  }
}
