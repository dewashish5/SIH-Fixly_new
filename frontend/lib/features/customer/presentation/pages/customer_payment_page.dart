import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/utils/toast_utils.dart';

class CustomerPaymentPage extends StatefulWidget {
  const CustomerPaymentPage({super.key, this.bookingId});

  final String? bookingId;

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<BookingFlowCubit>();
      cubit.refreshBooking(widget.bookingId);
      final id = widget.bookingId ?? cubit.state.booking?.id;
      if (id != null && id.isNotEmpty) {
        cubit.listenToSocketUpdates(id);
      }
    });
  }

  Future<void> _handlePay(double payableAmount) async {
    final cubit = context.read<BookingFlowCubit>();
    final success = await cubit.payWithRazorpay(
      bookingId: widget.bookingId,
      amountOverride: payableAmount,
    );
    if (!mounted) return;
    if (success) {
      context.pushReplacement(RouteNames.customerRating);
      return;
    }
    final error = cubit.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      ToastUtils.showToast(context: context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingFlowCubit, BookingFlowState>(
      listenWhen: (previous, current) =>
          previous.step != current.step ||
          previous.booking?.paymentStatus != current.booking?.paymentStatus,
      listener: (context, state) {
        if (state.step == BookingStatus.rating || state.step == BookingStatus.paid || state.booking?.paymentStatus == 'PAID') {
          context.pushReplacement(RouteNames.customerRating);
        }
      },
      child: AppScaffold(
        title: 'Payment & Invoice',
        showBack: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            final bId = widget.bookingId ?? context.read<BookingFlowCubit>().state.booking?.id;
            if (bId != null && bId.isNotEmpty) {
              context.go(RouteNames.bookingDetailPath(bId));
            } else {
              context.go(RouteNames.customerHome);
            }
          }
        },
        body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          final booking = state.booking;
          final extraPartsTotal = booking?.extraPartsTotal;
          final double extraParts = (extraPartsTotal != null && extraPartsTotal > 0)
              ? extraPartsTotal
              : (booking?.addOns.isNotEmpty ?? false
                  ? booking!.addOns.fold<double>(0.0, (s, a) => s + (a.price * a.quantity))
                  : 0.0);
          final double platform = booking?.platformFee ?? 0.0;
          final double urgent = booking?.urgentFee ?? 0.0;

          final bookingTotal = booking?.totalAmount;
          final invoiceTotal = booking?.invoice?.totalAmount;
          // Authoritative total amount from backend (which ALREADY includes baseFee + extraParts + platform + urgent):
          final double amount = (bookingTotal != null && bookingTotal > 0)
              ? bookingTotal
              : ((invoiceTotal != null && invoiceTotal > 0)
                  ? invoiceTotal
                  : state.displayPrice);

          // Base service fee: if explicitly provided and > 0, use it.
          // Otherwise derive base = total - extraParts - platform - urgent
          final baseFee = booking?.baseServiceFee;
          final double? baseServiceFee = (baseFee != null && baseFee > 0)
              ? baseFee
              : (amount > 0 && amount >= (extraParts + platform + urgent)
                  ? (amount - extraParts - platform - urgent)
                  : booking?.estimatedPrice);
          
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
                          if (baseServiceFee != null && baseServiceFee > 0)
                            _InvoiceRow('Base service fee', baseServiceFee),
                          if (platform > 0)
                            _InvoiceRow('Platform fee', platform),
                          if ((booking?.urgentFee ?? 0) > 0)
                            _InvoiceRow('Urgent / SOS fee', booking!.urgentFee!),
                          if (extraParts > 0 || (booking?.addOns.isNotEmpty ?? false)) ...[
                            _InvoiceRow(
                              'Extra parts & materials',
                              extraParts,
                            ),
                            if (booking != null && booking.addOns.isNotEmpty)
                              ...booking.addOns.map((part) => Padding(
                                padding: const EdgeInsets.only(left: 12, top: 2, bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '• ${part.title} (x${part.quantity})',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      '₹${(part.price * part.quantity).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )),
                          ],
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
                    onPressed: state.isLoading ? null : () => _handlePay(amount),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
