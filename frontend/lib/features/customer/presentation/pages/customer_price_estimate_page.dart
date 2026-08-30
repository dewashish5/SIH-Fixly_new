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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.priceEstimate,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final service = state.service;
          final price = state.displayPrice;

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
                _PriceRow(label: 'Base service fee', amount: price * 0.7),
                _PriceRow(label: 'Platform fee', amount: price * 0.1),
                _PriceRow(label: 'Insurance', amount: price * 0.05),
                const Divider(height: 24),
                _PriceRow(
                  label: 'Estimated Total',
                  amount: price,
                  bold: true,
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
    required this.amount,
    this.bold = false,
  });

  final String label;
  final double amount;
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
            '₹${amount.toInt()}',
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
