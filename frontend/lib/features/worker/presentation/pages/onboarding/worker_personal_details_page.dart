import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerPersonalDetailsPage extends StatefulWidget {
  const WorkerPersonalDetailsPage({super.key});

  @override
  State<WorkerPersonalDetailsPage> createState() =>
      _WorkerPersonalDetailsPageState();
}

class _WorkerPersonalDetailsPageState extends State<WorkerPersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<WorkerOnboardingCubit>().state.formData.fullName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    final cubit = context.read<WorkerOnboardingCubit>();
    cubit.updateFullName(_nameController.text);
    if (_formKey.currentState?.validate() ?? false) {
      cubit.setStep(1);
      context.push(RouteNames.workerOnboardingAadhaar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkerOnboardingLayout(
      step: 1,
      title: context.l10n.personalDetails,
      onContinue: _continue,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your name as on Aadhaar and PAN.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Rajesh Kumar',
              validator: (v) => Validators.requiredField(v, label: 'Full name'),
              onChanged: context.read<WorkerOnboardingCubit>().updateFullName,
            ),
          ],
        ),
      ),
    );
  }
}
