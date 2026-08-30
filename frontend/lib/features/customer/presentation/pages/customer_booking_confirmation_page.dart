import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/tracking_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerBookingConfirmationPage extends StatelessWidget {
  const CustomerBookingConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<BookingFlowCubit>().state;

    return AppScaffold(
      title: context.l10n.bookingConfirmed,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.accent,
              ),
            ).animate().scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),
            Text(
              'Thank you!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking has been completed successfully',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Service',
                    value: state.service?.title ?? 'Service',
                  ),
                  _DetailRow(
                    label: 'Worker',
                    value: state.booking?.workerName ?? 'Rajesh Kumar',
                  ),
                  _DetailRow(
                    label: 'Amount Paid',
                    value: '₹${state.displayPrice.toInt()}',
                  ),
                  _DetailRow(
                    label: 'Booking ID',
                    value: state.booking?.id ?? 'B-${DateTime.now().millisecondsSinceEpoch}',
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: 'Completed & Paid',
                    valueColor: AppColors.accent,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () {
                context.read<BookingFlowCubit>().reset();
                context.read<TrackingCubit>().reset();
                context.go(RouteNames.customerHome);
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'View Order History',
              onPressed: () => context.push(RouteNames.sharedOrderHistory),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.outline,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
