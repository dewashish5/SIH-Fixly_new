import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../shared/models/models.dart';
import '../../../../../shared/widgets/shared_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';

class WorkerOnboardingStatusPage extends StatefulWidget {
  const WorkerOnboardingStatusPage({super.key});

  @override
  State<WorkerOnboardingStatusPage> createState() =>
      _WorkerOnboardingStatusPageState();
}

class _WorkerOnboardingStatusPageState
    extends State<WorkerOnboardingStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerOnboardingCubit>().refreshKycStatus();
    });
  }

  Future<void> _refresh() async {
    final cubit = context.read<WorkerOnboardingCubit>();
    await cubit.refreshKycStatus();
    if (!mounted) return;
    final msg = cubit.state.errorMessage;
    if (cubit.state.status == WorkerOnboardingStatus.failure && msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiException.userFacingMessage(msg)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final kyc = state.kycStatus;
        final loading = state.status == WorkerOnboardingStatus.loading;

        return AppScaffold(
          title: context.l10n.kycStatus,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kyc == KycReviewStatus.approved
                    ? 'You are approved'
                    : 'Application under review',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                kyc == KycReviewStatus.approved
                    ? 'Your KYC is verified. Set availability to start receiving jobs.'
                    : 'Review usually takes 24–48 hours. Pull refresh or tap below to check status.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Column(
                  children: [
                    KycTrackerStep(
                      label: 'Submitted',
                      isCompleted:
                          kyc.index >= KycReviewStatus.submitted.index,
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
                  label: loading ? 'Checking…' : 'Refresh status',
                  onPressed: loading ? null : _refresh,
                ),
              if (loading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
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
