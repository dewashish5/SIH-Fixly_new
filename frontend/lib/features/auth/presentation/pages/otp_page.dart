import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/app_session_cubit.dart';
import '../../../../core/utils/toast_utils.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  static const _cooldownSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  late final AnimationController _cooldownController;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _cooldownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cooldownSeconds),
    )..forward(from: 0);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownController.dispose();
    super.dispose();
  }

  int get _secondsLeft =>
      (_cooldownSeconds * (1 - _cooldownController.value)).ceil().clamp(
            0,
            _cooldownSeconds,
          );

  bool get _canResend =>
      !_resending && _cooldownController.status == AnimationStatus.completed;

  void _startCooldown() {
    _cooldownController.forward(from: 0);
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

    ToastUtils.showError(context: context, message: cubit.state.errorMessage ?? 'Invalid OTP. Please try again.');
    cubit.resetOtpStatus();
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final l10n = context.l10n;
    final cubit = context.read<AppSessionCubit>();

    setState(() => _resending = true);

    await LocationService.instance.ensureForSignup(context);

    final success = await cubit.resendSignupOtp();

    if (!mounted) return;

    setState(() => _resending = false);

    if (success) {
      _startCooldown();
      ToastUtils.showToast(context: context, message: l10n.otpResent);
      return;
    }

    final msg = cubit.state.errorMessage;
    if (msg != null) {
      ToastUtils.showError(context: context, message: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loading = state.status == AppSessionStatus.loading;
        final email = state.email?.trim() ?? '';

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
                    tooltip: l10n.goBack,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.verifyOtp,
                  style: Theme.of(context).textTheme.headlineMedium,
                )
                    .animate()
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 20),
                _OtpEmailBanner(
                  label: l10n.otpSentTo,
                  email: email.isNotEmpty ? email : l10n.email,
                )
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 300.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _otpController,
                  label: 'OTP',
                  hint: '6-digit code',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: Validators.otp,
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _cooldownController,
                  builder: (context, child) {
                    return _OtpResendControl(
                      canResend: _canResend,
                      resending: _resending,
                      secondsLeft: _secondsLeft,
                      progress: 1 - _cooldownController.value,
                      resendLabel: l10n.resendOtp,
                      cooldownLabel: l10n.resendOtpIn(_secondsLeft),
                      onResend: _resendOtp,
                    );
                  },
                ),
                const Spacer(),
                PrimaryButton(
                  label: l10n.verifyOtp,
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

class _OtpEmailBanner extends StatelessWidget {
  const _OtpEmailBanner({
    required this.label,
    required this.email,
  });

  final String label;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: context.isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.muted,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpResendControl extends StatelessWidget {
  const _OtpResendControl({
    required this.canResend,
    required this.resending,
    required this.secondsLeft,
    required this.progress,
    required this.resendLabel,
    required this.cooldownLabel,
    required this.onResend,
  });

  final bool canResend;
  final bool resending;
  final int secondsLeft;
  final double progress;
  final String resendLabel;
  final String cooldownLabel;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Center(
      child: canResend
          ? TextButton.icon(
              onPressed: resending ? null : onResend,
              icon: resending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(Icons.refresh_rounded, color: scheme.primary),
              label: Text(
                resendLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor:
                            scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                        color: scheme.primary,
                      ),
                      Text(
                        '${secondsLeft}s',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cooldownLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.muted,
                      ),
                ),
              ],
            ),
    );
  }
}
