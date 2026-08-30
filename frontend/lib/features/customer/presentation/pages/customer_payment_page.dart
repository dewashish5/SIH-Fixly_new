import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerPaymentPage extends StatefulWidget {
  const CustomerPaymentPage({super.key});

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  String _method = 'upi';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.payment,
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
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
                    state.service?.title ?? 'Service payment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _PaymentOption(
                  icon: Icons.account_balance,
                  label: 'UPI',
                  subtitle: 'Google Pay, PhonePe, Paytm',
                  selected: _method == 'upi',
                  onTap: () => setState(() => _method = 'upi'),
                ),
                _PaymentOption(
                  icon: Icons.credit_card,
                  label: 'Card',
                  subtitle: 'Visa, Mastercard, RuPay',
                  selected: _method == 'card',
                  onTap: () => setState(() => _method = 'card'),
                ),
                _PaymentOption(
                  icon: Icons.money,
                  label: 'Cash',
                  subtitle: 'Pay after service',
                  selected: _method == 'cash',
                  onTap: () => setState(() => _method = 'cash'),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Pay ₹${amount.toInt()}',
                  loading: state.isLoading,
                  onPressed: () async {
                    await context.read<BookingFlowCubit>().completePayment();
                    if (context.mounted) {
                      context.push(RouteNames.customerRating);
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

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
