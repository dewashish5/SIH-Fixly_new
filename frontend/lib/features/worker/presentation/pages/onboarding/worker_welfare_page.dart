import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../shared/widgets/shared_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerWelfarePage extends StatefulWidget {
  const WorkerWelfarePage({super.key});

  @override
  State<WorkerWelfarePage> createState() => _WorkerWelfarePageState();
}

class _WorkerWelfarePageState extends State<WorkerWelfarePage> {
  late final TextEditingController _uanController;

  @override
  void initState() {
    super.initState();
    final data = context.read<WorkerOnboardingCubit>().state.formData;
    _uanController = TextEditingController(text: data.eshramUan);
  }

  @override
  void dispose() {
    _uanController.dispose();
    super.dispose();
  }

  void _continue() {
    context.read<WorkerOnboardingCubit>().setStep(8);
    context.push(RouteNames.workerOnboardingBank);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        return WorkerOnboardingLayout(
          step: 8,
          title: context.l10n.welfareInsurance,
          onContinue: _continue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InsuranceBadge(),
              const SizedBox(height: 16),
              Text(
                'e-Shram registration links you to PMSBY accident cover '
                '(₹2,00,000) and cooperative welfare benefits.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I have an e-Shram UAN'),
                value: state.formData.hasEshram,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : null,
                ),
                onChanged:
                    context.read<WorkerOnboardingCubit>().updateHasEshram,
              ),
              if (state.formData.hasEshram) ...[
                const SizedBox(height: 8),
                AppTextField(
                  controller: _uanController,
                  label: 'e-Shram UAN',
                  hint: 'ESHRAM1234567890',
                  onChanged:
                      context.read<WorkerOnboardingCubit>().updateEshramUan,
                ),
              ],
              const SizedBox(height: 16),
              const AppCard(
                child: Text(
                  'No UAN yet? Cooperative will help register after approval.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
