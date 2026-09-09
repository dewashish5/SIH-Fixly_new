import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../cubit/booking_flow_cubit.dart';

class CustomerEstimationReviewPage extends StatefulWidget {
  final String bookingId;

  const CustomerEstimationReviewPage({super.key, required this.bookingId});

  @override
  State<CustomerEstimationReviewPage> createState() => _CustomerEstimationReviewPageState();
}

class _CustomerEstimationReviewPageState extends State<CustomerEstimationReviewPage> {
  bool _isLoading = false;

  Future<void> _acceptEstimation() async {
    setState(() => _isLoading = true);
    try {
      final repo = BookingsApiRepository();
      await repo.acceptEstimation(widget.bookingId);
      if (mounted) {
        ToastUtils.showSuccess(context: context, message: 'Estimation accepted');
        context.read<BookingFlowCubit>().refreshBooking(widget.bookingId);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context: context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectEstimation() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Estimation?'),
        content: const Text(
            'If you reject this estimation and cancel the booking now, you will still be charged the base service fee. Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject & Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = BookingsApiRepository();
      await repo.cancel(widget.bookingId);
      if (mounted) {
        ToastUtils.showSuccess(context: context, message: 'Booking cancelled');
        context.go(RouteNames.customerOrders);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context: context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookingFlowCubit>().state;
    final booking = state.booking;

    if (booking == null) {
      return const AppScaffold(
        title: 'Review Estimation',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final labor = booking.baseServiceFee ?? 0.0;
    final parts = booking.extraPartsTotal ?? 0.0;
    final sc = booking.platformFee ?? 0.0; 
    final total = booking.totalAmount ?? booking.estimatedPrice;

    return AppScaffold(
      title: 'Review Estimation',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your worker has submitted a price estimation for this job.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildRow('Labor Cost', labor),
                  const SizedBox(height: 8),
                  _buildRow('Parts Cost', parts),
                  const SizedBox(height: 8),
                  _buildRow('Service / Platform Fee', sc),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Accept Estimation',
              loading: _isLoading,
              onPressed: _acceptEstimation,
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Reject & Cancel',
              onPressed: _isLoading ? null : _rejectEstimation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
