import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../cubit/booking_flow_cubit.dart';

class CustomerAddPartsPage extends StatefulWidget {
  const CustomerAddPartsPage({super.key});

  @override
  State<CustomerAddPartsPage> createState() => _CustomerAddPartsPageState();
}

class _CustomerAddPartsPageState extends State<CustomerAddPartsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingFlowCubit>().refreshBooking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.addParts,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final booking = state.booking;
          final addOns = booking?.addOns ?? const [];
          final partsTotal = booking?.extraPartsTotal ??
              addOns.fold<double>(
                0,
                (sum, item) => sum + item.price * item.quantity,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parts added by worker',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: state.isLoading && addOns.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : addOns.isEmpty
                        ? Center(
                            child: Text(
                              'No extra parts added yet.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            itemCount: addOns.length,
                            itemBuilder: (context, index) {
                              final part = addOns[index];
                              final lineTotal = part.price * part.quantity;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              part.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            Text(
                                              '₹${part.price.toInt()} × ${part.quantity}',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${lineTotal.toInt()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).appListEnter(
                                context,
                                index: index,
                                id: part.title,
                              );
                            },
                          ),
              ),
              if (booking != null) ...[
                const Divider(),
                if (booking.baseServiceFee != null)
                  _SummaryRow('Base service', booking.baseServiceFee!),
                if (partsTotal > 0)
                  _SummaryRow('Extra parts', partsTotal),
                if (booking.platformFee != null)
                  _SummaryRow('Platform fee', booking.platformFee!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total due',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '₹${state.displayPrice.toInt()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Approve & Pay',
                onPressed: booking == null
                    ? null
                    : () => context.push(RouteNames.customerPayment),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount);

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text('₹${amount.toInt()}'),
        ],
      ),
    );
  }
}
