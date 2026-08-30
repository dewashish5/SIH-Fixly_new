import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerPanPage extends StatefulWidget {
  const WorkerPanPage({super.key});

  @override
  State<WorkerPanPage> createState() => _WorkerPanPageState();
}

class _WorkerPanPageState extends State<WorkerPanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _panController;

  @override
  void initState() {
    super.initState();
    _panController = TextEditingController(
      text: context.read<WorkerOnboardingCubit>().state.formData.pan,
    );
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  void _continue() {
    final cubit = context.read<WorkerOnboardingCubit>();
    cubit.updatePan(_panController.text);
    if (_formKey.currentState?.validate() ?? false) {
      cubit.setStep(3);
      context.push(RouteNames.workerOnboardingSelfie);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkerOnboardingLayout(
      step: 3,
      title: context.l10n.panVerification,
      onContinue: _continue,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PAN must match your name and selfie for verification.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _panController,
              label: 'PAN number',
              hint: 'ABCDE1234F',
              maxLength: 10,
              validator: Validators.pan,
              onChanged: context.read<WorkerOnboardingCubit>().updatePan,
            ),
            const SizedBox(height: 8),
            Text(
              'Format: 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F). '
              '4th letter must be P for individuals.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
