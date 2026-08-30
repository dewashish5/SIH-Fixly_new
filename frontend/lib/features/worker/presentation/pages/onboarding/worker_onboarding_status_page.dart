import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../shared/widgets/shared_widgets.dart';
import '../../../../../shared/models/models.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerOnboardingStatusPage extends StatelessWidget {
  const WorkerOnboardingStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final kyc = state.kycStatus;

        return AppScaffold(
          title: context.l10n.kycStatus,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Application under review',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Review usually takes 24–48 hours. We will notify you when approved.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Column(
                  children: [
                    KycTrackerStep(
                      label: 'Submitted',
                      isCompleted: kyc.index >= KycReviewStatus.submitted.index,
                      isActive: kyc == KycReviewStatus.submitted,
                    ),
                    const SizedBox(height: 16),
                    KycTrackerStep(
                      label: 'In review',
                      isCompleted: kyc == KycReviewStatus.approved,
                      isActive: kyc == KycReviewStatus.inReview,
                    ),
                    const SizedBox(height: 16),
                    KycTrackerStep(
                      label: 'Approved',
                      isCompleted: kyc == KycReviewStatus.approved,
                      isActive: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (kyc != KycReviewStatus.approved)
                SecondaryButton(
                  label: 'Refresh status (demo)',
                  onPressed: () =>
                      context.read<WorkerOnboardingCubit>().refreshKycStatus(),
                ),
              const Spacer(),
              if (kyc == KycReviewStatus.approved)
                PrimaryButton(
                  label: 'Set availability',
                  onPressed: () =>
                      context.push(RouteNames.workerOnboardingAvailability),
                )
              else
                PrimaryButton(
                  label: 'Back to home',
                  onPressed: () => context.go(RouteNames.workerDashboard),
                ),
            ],
          ),
        );
      },
    );
  }
}
