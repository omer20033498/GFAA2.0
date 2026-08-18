import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../onboarding_questions.dart';
import 'multi_select_question.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  Set<String> _supportInterests = {};
  Set<String> _griefContext = {};
  bool _isSaving = false;

  Future<void> _finish() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _isSaving = true);
    await ref.read(profileRepositoryProvider).saveOnboardingAnswers(userId, {
      'support_interests': _supportInterests.toList(),
      'grief_context': _griefContext.toList(),
    });
    // No further navigation needed: the root app widget watches the
    // profile stream and will swap away from onboarding once
    // onboarding_answers is non-empty.
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = _step == 0;
    final canContinue = isFirstStep ? _supportInterests.isNotEmpty : _griefContext.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(step: _step, totalSteps: 2),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: isFirstStep
                      ? MultiSelectQuestion(
                          question: supportInterestsQuestion,
                          options: supportInterestsOptions,
                          selected: _supportInterests,
                          onChanged: (next) => setState(() => _supportInterests = next),
                        )
                      : MultiSelectQuestion(
                          question: griefContextQuestion,
                          options: griefContextOptions,
                          selected: _griefContext,
                          onChanged: (next) => setState(() => _griefContext = next),
                          accentWord: 'GFAA',
                        ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: !canContinue || _isSaving
                    ? null
                    : isFirstStep
                        ? () => setState(() => _step = 1)
                        : _finish,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isFirstStep ? 'Next' : 'Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Step ${step + 1} of $totalSteps',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < totalSteps; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? AppColors.deepGreen : AppColors.softSage,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
