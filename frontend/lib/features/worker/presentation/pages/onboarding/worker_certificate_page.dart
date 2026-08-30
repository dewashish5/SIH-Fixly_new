import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerCertificatePage extends StatelessWidget {
  const WorkerCertificatePage({super.key});

  void _upload(BuildContext context) {
    context.read<WorkerOnboardingCubit>().updateCertificateUploaded(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate uploaded (mock)')),
    );
  }

  void _continue(BuildContext context) {
    final cubit = context.read<WorkerOnboardingCubit>();
    final error = cubit.validateStep(5);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    cubit.setStep(5);
    context.push(RouteNames.workerOnboardingSkills);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        return WorkerOnboardingLayout(
          step: 5,
          title: context.l10n.skillCertificate,
          onContinue: () => _continue(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload trade certificate or license for your primary skill.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    Icon(
                      state.formData.certificateUploaded
                          ? Icons.task_outlined
                          : Icons.upload_file_outlined,
                      size: 48,
                      color: state.formData.certificateUploaded
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.formData.certificateUploaded
                          ? 'certificate.pdf uploaded'
                          : 'PDF or JPG up to 5 MB',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: state.formData.certificateUploaded
                          ? 'Replace file'
                          : 'Upload certificate',
                      onPressed: () => _upload(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
