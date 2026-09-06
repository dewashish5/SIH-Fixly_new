import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../payments/services/razorpay_checkout_service.dart';

class CustomerInvoicePage extends StatefulWidget {
  const CustomerInvoicePage({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<CustomerInvoicePage> createState() => _CustomerInvoicePageState();
}

class _CustomerInvoicePageState extends State<CustomerInvoicePage> {
  late Future<BookingInvoice> _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = BookingsApiRepository().invoice(widget.bookingId);
  }

  void _reload() {
    setState(() {
      _invoice = BookingsApiRepository().invoice(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Billing invoice',
      body: FutureBuilder<BookingInvoice>(
        future: _invoice,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(snapshot.error?.toString() ?? 'Invoice unavailable'),
            );
          }
          return _InvoiceContent(
            invoice: snapshot.data!,
            onPaymentSuccess: _reload,
          );
        },
      ),
    );
  }
}

class _InvoiceContent extends StatefulWidget {
  const _InvoiceContent({
    required this.invoice,
    required this.onPaymentSuccess,
  });

  final BookingInvoice invoice;
  final VoidCallback onPaymentSuccess;

  @override
  State<_InvoiceContent> createState() => _InvoiceContentState();
}

class _InvoiceContentState extends State<_InvoiceContent> {
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();
  bool _isPaying = false;

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _payWithRazorpay() async {
    final invoice = widget.invoice;
    if (invoice.totalAmount <= 0) {
      ToastUtils.showToast(context: context, message: 'Invalid payment amount');
      return;
    }

    setState(() => _isPaying = true);
    try {
      final verified = await _razorpay.processPayment(
        bookingId: invoice.bookingId,
        amountRupees: invoice.totalAmount,
        description: '${invoice.serviceName} invoice payment',
        customerName: invoice.customerName,
        phone: invoice.customerPhone,
      );

      if (!mounted) return;
      setState(() => _isPaying = false);

      if (verified) {
        ToastUtils.showToast(context: context, message: 'Payment successful!');
        widget.onPaymentSuccess();
      } else {
        ToastUtils.showToast(context: context, message: 'Payment verification failed');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ToastUtils.showToast(context: context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ToastUtils.showToast(context: context, message: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final theme = Theme.of(context);
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invoice.serviceName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _Status(status: invoice.paymentStatus ?? 'PENDING'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.bookingId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              if (invoice.workerName != null) ...[
                const SizedBox(height: 16),
                _InfoLine(
                  icon: Icons.person_outline,
                  label: 'Professional',
                  value: invoice.workerName!,
                ),
              ],
              if (invoice.customerName != null) ...[
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.account_circle_outlined,
                  label: 'Customer',
                  value: invoice.customerName!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              _AmountLine('Base service fee', invoice.baseServiceFee),
              _AmountLine('Extra parts', invoice.extraPartsTotal),
              _AmountLine('Platform fee', invoice.platformFee),
              const Divider(height: 24),
              _AmountLine(
                'Total amount',
                invoice.totalAmount,
                emphasized: true,
              ),
              if (invoice.paymentMethod != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payment method: ${invoice.paymentMethod}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
              if (invoice.transactionId != null &&
                  invoice.transactionId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Razorpay ID: ${invoice.transactionId}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (invoice.addOns.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Added parts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final part in invoice.addOns)
                  _AmountLine(
                    '${part.title} x${part.quantity}',
                    part.price * part.quantity,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (invoice.paymentStatus != 'PAID') ...[
          PrimaryButton(
            label: 'Pay ₹${invoice.totalAmount.toInt()} with Razorpay',
            loading: _isPaying,
            onPressed: _isPaying ? null : _payWithRazorpay,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Close invoice',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ] else ...[
          PrimaryButton(
            label: 'Close invoice',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine(this.label, this.amount, {this.emphasized = false});

  final String label;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: emphasized ? AppColors.primary : null,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 10),
      Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.replaceAll('_', ' ')),
    labelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    ),
    backgroundColor: AppColors.primary50,
    side: BorderSide.none,
  );
}
