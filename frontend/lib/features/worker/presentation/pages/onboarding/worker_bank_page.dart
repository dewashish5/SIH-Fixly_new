import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerBankPage extends StatefulWidget {
  const WorkerBankPage({super.key});

  @override
  State<WorkerBankPage> createState() => _WorkerBankPageState();
}

class _WorkerBankPageState extends State<WorkerBankPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankController;
  late final TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    final data = context.read<WorkerOnboardingCubit>().state.formData;
    _bankController = TextEditingController(text: data.bankAccount);
    _upiController = TextEditingController(text: data.upiId);
  }

  @override
  void dispose() {
    _bankController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<WorkerOnboardingCubit>();
    cubit
      ..updateBankAccount(_bankController.text)
      ..updateUpiId(_upiController.text);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = cubit.validateStep(9);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await cubit.submitOnboarding();
    if (mounted) {
      context.go(RouteNames.workerOnboardingStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        return WorkerOnboardingLayout(
          step: 9,
          title: context.l10n.bankUpi,
          continueLabel: 'Submit for review',
          loading: state.status == WorkerOnboardingStatus.loading,
          onContinue: _submit,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payouts go to your bank or UPI. Also linked to cooperative welfare fund.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bank/UPI details are linked to the cooperative welfare fund for emergency support.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _bankController,
                  label: 'Bank account number',
                  hint: 'Optional if UPI provided',
                  keyboardType: TextInputType.number,
                  onChanged:
                      context.read<WorkerOnboardingCubit>().updateBankAccount,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _upiController,
                  label: 'UPI ID',
                  hint: 'name@upi',
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      if (_bankController.text.trim().isEmpty) {
                        return 'Enter bank account or UPI ID';
                      }
                      return null;
                    }
                    return Validators.upi(v);
                  },
                  onChanged:
                      context.read<WorkerOnboardingCubit>().updateUpiId,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
