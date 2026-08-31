import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerBookingPage extends StatefulWidget {
  const CustomerBookingPage({super.key});

  @override
  State<CustomerBookingPage> createState() => _CustomerBookingPageState();
}

class _CustomerBookingPageState extends State<CustomerBookingPage> {
  late final TextEditingController _addressController;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: AppLocation.instance.addressLabel ?? '',
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingCubit = context.read<BookingFlowCubit>();
    final service = bookingCubit.state.service;

    return AppScaffold(
      title: context.l10n.bookService,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (service != null) ...[
                StepProgressHeader(
                  currentStep: 1,
                  totalSteps: 5,
                  title: service.title,
                ),
              ],
              AppTextField(
                controller: _addressController,
                label: 'Service Address',
                hint: AppLocation.instance.addressLabel ??
                    'Uses your current location',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Address required' : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Preferred Date & Time',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(DateFormat('hh:mm a').format(_selectedDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Additional Notes',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue (optional)',
                ),
              ),
              const SizedBox(height: 32),
              BlocBuilder<BookingFlowCubit, BookingFlowState>(
                builder: (context, state) {
                  return PrimaryButton(
                    label: 'Continue to Estimate',
                    loading: state.isLoading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      await bookingCubit.submitBookingDetails(
                        address: _addressController.text.trim(),
                        scheduledAt: _selectedDate,
                      );
                      if (context.mounted) {
                        context.push(RouteNames.customerPriceEstimate);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
