import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/tracking_cubit.dart';

class CustomerBookingConfirmationPage extends StatelessWidget {
  const CustomerBookingConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<BookingFlowCubit>().state;

    return AppScaffold(
      title: 'Order Placed',
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ).animate().scale(
              begin: const Offset(0.3, 0.3),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 20),
            Text(
              'Booking Order Placed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFFD97706)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Waiting for worker acceptance',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Your service request has been created and sent to the worker.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            AppCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Service',
                    value: state.service?.title ?? 'Service',
                  ),
                  _DetailRow(
                    label: 'Worker',
                    value: state.booking?.workerName ?? 'Assigned worker',
                  ),
                  if (state.address != null)
                    _DetailRow(label: 'Address', value: state.address!),
                  _DetailRow(
                    label: 'Estimated amount',
                    value: '₹${state.displayPrice.toInt()}',
                  ),
                  _DetailRow(
                    label: 'Booking ID',
                    value:
                        state.booking?.id ??
                        'B-${DateTime.now().millisecondsSinceEpoch}',
                  ),
                  if (state.booking?.arrivalOtp != null)
                    _DetailRow(
                      label: 'Arrival OTP',
                      value: state.booking!.arrivalOtp!,
                      valueColor: AppColors.accent,
                    ),
                  const _DetailRow(
                    label: 'Status',
                    value: 'Waiting for worker acceptance',
                    valueColor: Color(0xFFD97706),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Order History',
              onPressed: () {
                context.read<BookingFlowCubit>().reset();
                context.read<TrackingCubit>().reset();
                context.go(RouteNames.customerOrders);
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Home Dashboard',
              onPressed: () {
                context.read<BookingFlowCubit>().reset();
                context.read<TrackingCubit>().reset();
                context.go(RouteNames.customerHome);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
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
