import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/app_session_cubit.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<AppSessionCubit>();
    final success = await cubit.verifyOtp(_otpController.text.trim());

    if (!mounted) return;

    if (success) {
      context.go(cubit.postAuthRoute());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid OTP. Please try again.'),
        backgroundColor: AppColors.error,
      ),
    );
    cubit.resetOtpStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final strings = context.strings(state.locale);
        final loading = state.status == AppSessionStatus.loading;
        final phone = state.phone ?? '';

        return AppScaffold(
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: strings.goBack,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.verifyOtp,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  phone.isNotEmpty
                      ? 'Code sent to +91 $phone'
                      : 'Enter the 6-digit code sent to your phone',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.muted,
                      ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _otpController,
                  label: 'OTP',
                  hint: '6-digit code',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: Validators.otp,
                ),
                const Spacer(),
                PrimaryButton(
                  label: strings.verifyOtp,
                  loading: loading,
                  onPressed: loading ? null : _verifyOtp,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
