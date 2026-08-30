import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerWorkStartedPage extends StatelessWidget {
  const CustomerWorkStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.workInProgress,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepProgressHeader(
                  currentStep: 4,
                  totalSteps: 5,
                  title: 'Work started',
                ),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.construction,
                      size: 48,
                      color: AppColors.tertiary,
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 3000.ms),
                ),
                const SizedBox(height: 24),
                Text(
                  '${state.booking?.workerName ?? "Worker"} is working on your service',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.service?.title ?? 'Service in progress',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppCard(
                  child: Column(
                    children: [
                      _StatusRow(
                        label: 'Worker arrived',
                        done: true,
                      ),
                      _StatusRow(
                        label: 'Diagnosis complete',
                        done: true,
                      ),
                      _StatusRow(
                        label: 'Repair in progress',
                        done: true,
                        active: true,
                      ),
                      _StatusRow(
                        label: 'Quality check',
                        done: false,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Add Parts (if needed)',
                  onPressed: () => context.push(RouteNames.customerAddParts),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Proceed to Payment',
                  onPressed: () async {
                    await context.read<BookingFlowCubit>().startWork();
                    if (context.mounted) {
                      context.push(RouteNames.customerPayment);
                    }
                  },
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.done,
    this.active = false,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done
                ? (active ? AppColors.tertiary : AppColors.secondary)
                : AppColors.outlineVariant,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
