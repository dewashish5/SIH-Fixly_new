import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/category_chip.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerSkillsPage extends StatelessWidget {
  const WorkerSkillsPage({super.key});

  void _continue(BuildContext context) {
    final cubit = context.read<WorkerOnboardingCubit>();
    final error = cubit.validateStep(6);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    cubit.setStep(6);
    context.push(RouteNames.workerOnboardingArea);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.locale;

    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        return WorkerOnboardingLayout(
          step: 6,
          title: context.l10n.selectSkills,
          onContinue: () => _continue(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose all categories you can serve. Select at least one.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in ServiceCategories.all)
                    CategoryChip(
                      label: category.nameFor(locale),
                      imageUrl: category.imageUrl,
                      fallbackIcon: category.fallbackIcon,
                      selected: state.formData.skills.contains(category.id),
                      onTap: () => context
                          .read<WorkerOnboardingCubit>()
                          .toggleSkill(category.id),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
