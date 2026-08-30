import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';

class WorkerSelfiePage extends StatelessWidget {
  const WorkerSelfiePage({super.key});

  void _capture(BuildContext context) {
    context.read<WorkerOnboardingCubit>().captureSelfie(
          imageUrl: AppImages.demoSelfie,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selfie captured (mock)')),
    );
  }

  void _retake(BuildContext context) {
    context.read<WorkerOnboardingCubit>().clearSelfie();
  }

  void _continue(BuildContext context) {
    final cubit = context.read<WorkerOnboardingCubit>();
    final error = cubit.validateStep(4);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    cubit.setStep(4);
    context.push(RouteNames.workerOnboardingCertificate);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final captured = state.formData.selfieVerified;
        final imageUrl = state.formData.selfieImageUrl;

        return WorkerOnboardingLayout(
          step: 4,
          title: context.l10n.selfieVerification,
          onContinue: () => _continue(context),
          child: Column(
            children: [
              Text(
                'Take a clear selfie for face match with PAN and Aadhaar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: captured ? AppColors.success : AppColors.outlineVariant,
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: captured && imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, _, _) => Icon(
                          Icons.face_retouching_natural,
                          size: 64,
                          color: AppColors.outline,
                        ),
                      )
                    : Icon(
                        Icons.face_retouching_natural,
                        size: 64,
                        color: AppColors.outline,
                      ),
              ),
              const SizedBox(height: 24),
              SecondaryButton(
                label: captured ? 'Retake selfie' : 'Capture selfie',
                onPressed: captured ? () => _retake(context) : () => _capture(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
