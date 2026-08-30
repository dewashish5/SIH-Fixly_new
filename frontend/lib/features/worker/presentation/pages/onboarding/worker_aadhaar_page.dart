import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerAadhaarPage extends StatefulWidget {
  const WorkerAadhaarPage({super.key});

  @override
  State<WorkerAadhaarPage> createState() => _WorkerAadhaarPageState();
}

class _WorkerAadhaarPageState extends State<WorkerAadhaarPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _aadhaarController;

  @override
  void initState() {
    super.initState();
    _aadhaarController = TextEditingController(
      text: context.read<WorkerOnboardingCubit>().state.formData.aadhaar,
    );
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  void _continue() {
    final cubit = context.read<WorkerOnboardingCubit>();
    cubit.updateAadhaar(_aadhaarController.text);
    if (_formKey.currentState?.validate() ?? false) {
      cubit.setStep(2);
      context.push(RouteNames.workerOnboardingPan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkerOnboardingLayout(
      step: 2,
      title: context.l10n.aadhaarVerification,
      onContinue: _continue,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Aadhaar is used for KYC and cooperative membership.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _aadhaarController,
              label: 'Aadhaar number',
              hint: '1234 5678 9012',
              keyboardType: TextInputType.number,
              maxLength: 14,
              validator: Validators.aadhaar,
              onChanged: context.read<WorkerOnboardingCubit>().updateAadhaar,
            ),
            const SizedBox(height: 16),
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data encrypted. Used only for verification.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
