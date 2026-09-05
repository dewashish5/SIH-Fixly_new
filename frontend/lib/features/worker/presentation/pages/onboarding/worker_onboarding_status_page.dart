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
import '../../../../../core/utils/toast_utils.dart';

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
      ToastUtils.showError(context: context, message: ApiException.userFacingMessage(msg));
      return;
    }
    // Only leave this screen when API says user.isVerified.
    if (cubit.state.kycStatus == KycReviewStatus.approved) {
      context.go(RouteNames.workerDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final status = state.kycStatus;
        final loading = state.status == WorkerOnboardingStatus.loading;
        final verified = status == KycReviewStatus.approved;
        final declined = status == KycReviewStatus.rejected;
        final declineText = (state.declineReason?.trim().isNotEmpty ?? false)
            ? state.declineReason!.trim()
            : 'Your request to join as a worker has been declined.';

        return AppScaffold(
          title: context.l10n.kycStatus,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                declined
                    ? 'Application declined'
                    : verified
                        ? 'You are verified'
                        : 'Application under review',
                style: textTheme.headlineSmall?.copyWith(
                  color: declined ? scheme.error : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                declined
                    ? 'Admin reviewed your application and did not approve it.'
                    : verified
                        ? 'Your application is verified. Continue to your worker dashboard.'
                        : 'We are reviewing your application. This usually takes 24–48 hours. Pull refresh or tap below — you can enter the app only after verification.',
                style: textTheme.bodyMedium,
              ),
              if (declined) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message from Fixly',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        declineText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!declined)
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
              if (!declined) const SizedBox(height: 16),
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
