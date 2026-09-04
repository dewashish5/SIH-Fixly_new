import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/app_session_cubit.dart';
import '../widgets/auth_screen_layout.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false; // instant local loader before cubit responds

  @override
  void initState() {
    super.initState();
    context.read<AppSessionCubit>().setAuthFlow(AuthFlow.signup);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AppSessionCubit get _cubit => context.read<AppSessionCubit>();

  Future<void> _handleSocial(Future<bool> Function() signUp) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final success = await signUp();
      if (!mounted || !success) {
        final msg = _cubit.state.errorMessage;
        if (mounted && msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      context.go(_cubit.postAuthRoute());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus(); // dismiss keyboard instantly
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    // Show loader immediately — before any async work.
    setState(() => _submitting = true);

    try {
      // Run GPS check concurrently with signup API — don't block UX waiting for it.
      // unawaited intentionally; signup API doesn't need GPS result to proceed.
      LocationService.instance.ensureForSignup(context).ignore();

      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final success = await _cubit.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: phoneDigits,
      );
      if (!mounted) return;
      if (!success) {
        final msg = _cubit.state.errorMessage;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      if (_cubit.state.status == AppSessionStatus.otpSent) {
        context.push(RouteNames.otp);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loading = _submitting || state.status == AppSessionStatus.loading;

        return AuthCurvedShell(
          compact: true,
          scrollable: true,
          footer: AuthLinkRow(
            prompt: l10n.alreadyHaveAccount,
            actionLabel: l10n.login,
            onTap: () => context.pop(),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthPageTitle(l10n.signUp, compact: true),
                const SizedBox(height: 16),
                AuthRoleToggle(
                  selectedRole: state.role,
                  customerLabel: l10n.customer,
                  workerLabel: l10n.worker,
                  onChanged: _cubit.setRole,
                  enabled: !loading,
                ),
                const SizedBox(height: 16),
                AuthUnderlineField(
                  dense: true,
                  controller: _nameController,
                  label: l10n.fullName,
                  hint: l10n.fullNameHint,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.requiredField(
                    value,
                    label: l10n.fullName,
                  ),
                ),
                const SizedBox(height: 14),
                AuthUnderlineField(
                  dense: true,
                  controller: _phoneController,
                  label: l10n.phoneNumber,
                  hint: l10n.phoneHint,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                  validator: Validators.phone,
                  prefix: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '+91',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 1.35,
                          color: context.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: context.ink.withValues(alpha: 0.55),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AuthUnderlineField(
                  dense: true,
                  controller: _emailController,
                  label: l10n.email,
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AuthUnderlineField(
                  dense: true,
                  controller: _passwordController,
                  label: l10n.password,
                  hint: l10n.passwordHint,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!loading) _signUp();
                  },
                  validator: (value) => Validators.requiredField(
                    value,
                    label: l10n.password,
                  ),
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.ink.withValues(alpha: 0.55),
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AuthDarkButton(
                  compact: true,
                  label: l10n.createAccount,
                  loading: loading,
                  onPressed: loading ? null : _signUp,
                ),
                const SizedBox(height: 12),
                AuthGoogleSquare(
                  compact: true,
                  onPressed: loading
                      ? null
                      : () => _handleSocial(_cubit.signInWithGoogle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
