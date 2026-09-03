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
      return;
    }
    // Only leave this screen when API says user.isVerified.
    if (cubit.state.kycStatus == KycReviewStatus.approved) {
      context.go(RouteNames.workerDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final status = state.kycStatus;
        final loading = state.status == WorkerOnboardingStatus.loading;
        final verified = status == KycReviewStatus.approved;

        return AppScaffold(
          title: context.l10n.kycStatus,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                verified
                    ? 'You are verified'
                    : 'Application under review',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                verified
                    ? 'Your application is verified. Continue to your worker dashboard.'
                    : 'We are reviewing your application. This usually takes 24–48 hours. Pull refresh or tap below — you can enter the app only after verification.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Column(
                  children: [
                    KycTrackerStep(
                      label: 'Submitted',
                      isCompleted:
                          status.index >= KycReviewStatus.submitted.index,
                      isActive: status == KycReviewStatus.submitted,
                    ),
                    const SizedBox(height: 16),
                    KycTrackerStep(
                      label: 'In review',
                      isCompleted: verified,
                      isActive: status == KycReviewStatus.inReview,
                    ),
                    const SizedBox(height: 16),
                    KycTrackerStep(
                      label: 'Verified',
                      isCompleted: verified,
                      isActive: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              if (verified)
                PrimaryButton(
                  label: 'Go to dashboard',
                  onPressed: () => context.go(RouteNames.workerDashboard),
                ),
            ],
          ),
        );
      },
    );
  }
}
