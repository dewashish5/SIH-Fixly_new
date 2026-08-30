import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/widgets/core_widgets.dart';

class WorkerOnboardingLayout extends StatelessWidget {
  const WorkerOnboardingLayout({
    required this.step,
    required this.title,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.loading = false,
    super.key,
  });

  final int step;
  final String title;
  final Widget child;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Worker onboarding',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepProgressHeader(
            currentStep: step,
            totalSteps: AppConstants.onboardingTotalSteps,
            title: title,
          ),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: continueLabel,
            onPressed: onContinue,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class OnboardingSection extends StatelessWidget {
  const OnboardingSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}
