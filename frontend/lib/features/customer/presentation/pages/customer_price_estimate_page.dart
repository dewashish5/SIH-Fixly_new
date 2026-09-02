import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerPriceEstimatePage extends StatelessWidget {
  const CustomerPriceEstimatePage({super.key});

  String _range(double min, double max) {
    if (min <= 0 && max <= 0) return '—';
    if (min == max) return '₹${min.toInt()}';
    return '₹${min.toInt()} – ₹${max.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.priceEstimate,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final service = state.service;
          final estimate = state.priceEstimate;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepProgressHeader(
                  currentStep: 2,
                  totalSteps: 5,
                  title: 'Review estimate',
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service != null)
                        Text(
                          service.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      if (state.address != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: AppColors.outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                state.address!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (state.scheduledAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 16, color: AppColors.outline),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM, hh:mm a')
                                  .format(state.scheduledAt!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.05),
                const SizedBox(height: 20),
                Text(
                  'Cost Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (estimate != null) ...[
                  _PriceRow(
                    label: 'Labor estimate',
                    value: _range(estimate.laborMin, estimate.laborMax),
                  ),
                  _PriceRow(
                    label: 'Materials & parts',
                    value: _range(estimate.materialsMin, estimate.materialsMax),
                  ),
                  _PriceRow(
                    label: 'Service fee',
                    value: '₹${estimate.serviceFee.toInt()}',
                  ),
                  const Divider(height: 24),
                  _PriceRow(
                    label: 'Estimated total',
                    value: _range(estimate.minTotal, estimate.maxTotal),
                    bold: true,
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Estimate unavailable. Base price from ₹${state.displayPrice.toInt()}.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '* Final price may vary based on parts & labour',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.outline,
                      ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Find Worker',
                  loading: state.isLoading,
                  onPressed: () async {
                    await context.read<BookingFlowCubit>().confirmEstimate();
                    if (context.mounted) {
                      context.push(RouteNames.customerFindingWorker);
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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.primary : null,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
