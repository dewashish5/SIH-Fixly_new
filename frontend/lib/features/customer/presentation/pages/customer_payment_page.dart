import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';

class CustomerPaymentPage extends StatefulWidget {
  const CustomerPaymentPage({super.key});

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingFlowCubit>().refreshBooking();
    });
  }

  Future<void> _handlePay() async {
    final cubit = context.read<BookingFlowCubit>();
    final success = await cubit.payWithRazorpay();
    if (!mounted) return;
    if (success) {
      final bookingId = cubit.state.booking?.id;
      if (bookingId != null) {
        context.push(RouteNames.customerInvoice.replaceFirst(':id', bookingId));
      } else {
        context.push(RouteNames.customerRating);
      }
      return;
    }
    final error = cubit.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.payment,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final booking = state.booking;
          final amount = state.displayPrice;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepProgressHeader(
                  currentStep: 5,
                  totalSteps: 5,
                  title: 'Complete payment',
                ),
                Center(
                  child: Text(
                    '₹${amount.toInt()}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    booking?.serviceTitle ??
                        state.service?.title ??
                        'Service payment',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                  ),
                ),
                const SizedBox(height: 24),
                if (booking != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        if (booking.baseServiceFee != null)
                          _InvoiceRow('Base service', booking.baseServiceFee!),
                        if ((booking.extraPartsTotal ?? 0) > 0)
                          _InvoiceRow('Extra parts', booking.extraPartsTotal!),
                        if (booking.platformFee != null)
                          _InvoiceRow('Platform fee', booking.platformFee!),
                        const Divider(height: 24),
                        _InvoiceRow('Total amount', amount, emphasized: true),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Secure payment powered by Razorpay. UPI, cards and supported wallets are available in the Razorpay checkout.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Pay ₹${amount.toInt()} with Razorpay',
                  loading: state.isLoading,
                  onPressed: state.isLoading ? null : _handlePay,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.label, this.amount, {this.emphasized = false});

  final String label;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
        ),
        Text(
          '₹${amount.toInt()}',
          style: TextStyle(
            color: emphasized ? AppColors.primary : null,
            fontWeight: emphasized ? FontWeight.w800 : null,
          ),
        ),
      ],
    ),
  );
}
