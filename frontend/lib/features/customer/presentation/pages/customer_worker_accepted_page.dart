import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerWorkerAcceptedPage extends StatelessWidget {
  const CustomerWorkerAcceptedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final worker = MockRepository.instance.workerById('w1');

    return AppScaffold(
      title: context.l10n.workerAssigned,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final workerName =
              state.booking?.workerName ?? worker?.name ?? 'Rajesh Kumar';

          return SingleChildScrollView(
            child: Column(
              children: [
                const StepProgressHeader(
                  currentStep: 3,
                  totalSteps: 5,
                  title: 'Worker accepted',
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 56,
                    color: AppColors.secondary,
                  ),
                ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 24),
                Text(
                  '$workerName accepted your booking!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your worker is preparing to head to your location',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (worker != null)
                  AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            worker.name[0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(worker.skills.join(' • ')),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: AppColors.tertiary),
                                  Text(' ${worker.rating}'),
                                  const SizedBox(width: 12),
                                  Text('${worker.jobsCompleted} jobs'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () =>
                              context.push('/customer/worker/${worker.id}'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Track Worker',
                  onPressed: () => context.push(RouteNames.customerTracking),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Contact Support',
                  onPressed: () => context.push(RouteNames.sharedSupportChat),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
