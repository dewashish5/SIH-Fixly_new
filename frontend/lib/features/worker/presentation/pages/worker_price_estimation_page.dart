import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../cubit/active_job_cubit.dart';

class WorkerPriceEstimationPage extends StatefulWidget {
  final String bookingId;

  const WorkerPriceEstimationPage({super.key, required this.bookingId});

  @override
  State<WorkerPriceEstimationPage> createState() => _WorkerPriceEstimationPageState();
}

class _WorkerPriceEstimationPageState extends State<WorkerPriceEstimationPage> {
  final TextEditingController _laborController = TextEditingController();
  final TextEditingController _partsController = TextEditingController();
  final TextEditingController _serviceChargeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _laborController.addListener(_calculateTotal);
    _partsController.addListener(_calculateTotal);
    _serviceChargeController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _laborController.dispose();
    _partsController.dispose();
    _serviceChargeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final labor = double.tryParse(_laborController.text) ?? 0.0;
    final parts = double.tryParse(_partsController.text) ?? 0.0;
    final sc = double.tryParse(_serviceChargeController.text) ?? 0.0;
    setState(() {
      _total = labor + parts + sc;
    });
  }

  Future<void> _submit() async {
    final labor = double.tryParse(_laborController.text);
    if (labor == null || labor < 0) {
      ToastUtils.showError(context: context, message: 'Please enter a valid labor cost');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = BookingsApiRepository();
      await repo.submitPriceEstimation(
        widget.bookingId,
        labor: labor,
        parts: double.tryParse(_partsController.text),
        serviceCharge: double.tryParse(_serviceChargeController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      if (mounted) {
        ToastUtils.showSuccess(context: context, message: 'Estimation submitted successfully');
        context.read<ActiveJobCubit>().load();
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Price Estimation',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Estimated Labor Cost (₹) *',
              controller: _laborController,
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Estimated Parts Cost (₹) (Optional)',
              controller: _partsController,
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Service Charge / Extra Work (₹) (Optional)',
              controller: _serviceChargeController,
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Notes (Optional)',
              controller: _notesController,
              keyboardType: TextInputType.text,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '₹${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Show Estimation to Customer',
              loading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Cancel',
              onPressed: _isLoading ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
