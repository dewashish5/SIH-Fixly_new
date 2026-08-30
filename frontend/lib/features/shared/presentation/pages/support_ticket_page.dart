import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/support_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class SupportTicketPage extends StatefulWidget {
  const SupportTicketPage({super.key});

  @override
  State<SupportTicketPage> createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<SupportCubit>().submitTicket(
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
        );
    if (mounted) {
      context.push('/system/complaintSubmitted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.supportTicket,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _subjectController,
              label: 'Subject',
              validator: (v) => Validators.requiredField(v, label: 'Subject'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your issue...',
              validator: (v) =>
                  Validators.requiredField(v, label: 'Description'),
            ),
            const Spacer(),
            BlocBuilder<SupportCubit, SupportState>(
              builder: (context, state) {
                return PrimaryButton(
                  label: 'Submit ticket',
                  loading: state.status == SupportStatus.submitting,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
