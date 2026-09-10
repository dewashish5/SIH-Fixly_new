import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/active_job_cubit.dart';
import '../../../../core/utils/toast_utils.dart';

class WorkerAddPartsPage extends StatefulWidget {
  const WorkerAddPartsPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<WorkerAddPartsPage> createState() => _WorkerAddPartsPageState();
}

class _WorkerAddPartsPageState extends State<WorkerAddPartsPage> {
  final List<Map<String, dynamic>> _parts = [];
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _addPart() {
    final title = _titleCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();
    if (title.isNotEmpty && priceStr.isNotEmpty) {
      final price = double.tryParse(priceStr);
      if (price != null) {
        setState(() {
          _parts.add({
            'title': title,
            'price': price,
          });
          _titleCtrl.clear();
          _priceCtrl.clear();
        });
      }
    }
  }

  Future<void> _requestPayment() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await context
        .read<ActiveJobCubit>()
        .finalizeBillingAndRequestPayment(List.from(_parts));
  }

  @override
  Widget build(BuildContext context) {
    double total = _parts.fold(0, (sum, part) => sum + (part['price'] as double));

    return BlocListener<ActiveJobCubit, ActiveJobState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ActiveJobStatus.awaitingPayment ||
            state.status == ActiveJobStatus.paymentReceived) {
          // Back to active job wait/payment-received UI — do not jump to rating yet.
          context.go(RouteNames.workerActiveJob);
        } else if (state.status == ActiveJobStatus.failure) {
          setState(() => _submitting = false);
          ToastUtils.showToast(
            context: context,
            message: state.error ?? 'Failed to request payment',
          );
        }
      },
      child: AppScaffold(
        title: 'Final Billing',
        body: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Add any extra parts used, then request payment.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _titleCtrl,
                    hint: 'Part name',
                    enabled: !_submitting,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _priceCtrl,
                    hint: 'Price',
                    keyboardType: TextInputType.number,
                    enabled: !_submitting,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                  onPressed: _submitting ? null : _addPart,
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _parts.length,
                itemBuilder: (context, index) {
                  final part = _parts[index];
                  return ListTile(
                    leading: const Icon(Icons.build_circle, color: AppColors.primary),
                    title: Text(part['title']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${part['price']}'),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: _submitting
                              ? null
                              : () {
                                  setState(() {
                                    _parts.removeAt(index);
                                  });
                                },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total added:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            if (_submitting)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(),
              )
            else ...[
              SecondaryButton(
                label: 'Skip Parts — Request Payment',
                onPressed: _requestPayment,
              ),
              const SizedBox(height: 12),
              SwipeActionButton(
                label: 'Swipe to Request Payment',
                enabled: !_submitting,
                onCompleted: _requestPayment,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
