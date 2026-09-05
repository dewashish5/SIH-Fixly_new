import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/utils/toast_utils.dart';

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
      context.push(RouteNames.customerRating);
      return;
    }
    final error = cubit.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      ToastUtils.showToast(context: context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payment & Invoice',
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final booking = state.booking;
          final amount = state.displayPrice;
          
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '5/5 Final Step',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '₹${amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AC6),
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Work Completed • Awaiting Payment',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Razorpay test mode',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Itemized invoice AppCard
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invoice Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (booking?.baseServiceFee != null)
                            _InvoiceRow('Base service fee', booking!.baseServiceFee!),
                          if ((booking?.extraPartsTotal ?? 0) > 0)
                            _InvoiceRow('Extra parts/services', booking!.extraPartsTotal!),
                          if (booking?.platformFee != null)
                            _InvoiceRow('Platform fee', booking!.platformFee!),
                          if (booking != null && booking.addOns.isNotEmpty)
                            ...booking.addOns.map((part) => _InvoiceRow(part.title, part.price)),
                          const Divider(height: 24, thickness: 1),
                          _InvoiceRow('Total', amount, isTotal: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Security badge
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outlined, color: Colors.grey, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Secured by Razorpay • Test mode',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bottom Sticky
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: PrimaryButton(
                    label: 'Pay ₹${amount.toInt()} Now',
                    loading: state.isLoading,
                    onPressed: state.isLoading ? null : _handlePay,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.label, this.amount, {this.isTotal = false});

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF0B1C30) : const Color(0xFF434655),
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF2563EB) : const Color(0xFF0B1C30),
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
