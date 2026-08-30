import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/profile_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    _nameController = TextEditingController(text: state.name);
    _phoneController = TextEditingController(text: state.phone);
    if (state.name.isEmpty) {
      context.read<ProfileCubit>().load();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<ProfileCubit>().updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaved)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.editProfile,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Full name',
              validator: (v) => Validators.requiredField(v, label: 'Name'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneController,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const Spacer(),
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                return PrimaryButton(
                  label: 'Save changes',
                  loading: state.status == ProfileStatus.loading,
                  onPressed: _save,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
