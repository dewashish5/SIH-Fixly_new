import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/app_session_cubit.dart';
import '../widgets/auth_credentials_fields.dart';
import '../widgets/auth_screen_layout.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  AuthInputMethod _method = AuthInputMethod.email;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    context.read<AppSessionCubit>().setAuthFlow(AuthFlow.signup);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  AppSessionCubit get _cubit => context.read<AppSessionCubit>();

  Future<void> _handleSocial(Future<bool> Function() signUp) async {
    final success = await signUp();
    if (!mounted || !success) return;
    context.go(_cubit.postAuthRoute());
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_method == AuthInputMethod.email) {
      final success = await _cubit.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted || !success) return;
      context.go(_cubit.postAuthRoute());
      return;
    }

    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    await _cubit.sendOtp(phone);
    if (!mounted) return;
    if (_cubit.state.status == AppSessionStatus.otpSent) {
      context.push(RouteNames.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loading = state.status == AppSessionStatus.loading;

        return AuthScreenLayout(
          title: l10n.signUp,
          subtitle: l10n.signUpSubtitle,
          footer: AuthLinkRow(
            prompt: l10n.alreadyHaveAccount,
            actionLabel: l10n.login,
            onTap: () => context.pop(),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthRoleSelector(
                  selectedRole: state.role,
                  customerLabel: l10n.customer,
                  workerLabel: l10n.worker,
                  customerSubtitle: l10n.customerRoleSubtitle,
                  workerSubtitle: l10n.workerRoleSubtitle,
                  onChanged: _cubit.setRole,
                  enabled: !loading,
                ),
                const SizedBox(height: 22),
                AuthSocialRow(
                  onGoogle:
                      loading ? null : () => _handleSocial(_cubit.signInWithGoogle),
                  onFacebook: loading
                      ? null
                      : () => _handleSocial(_cubit.signInWithFacebook),
                ),
                const SizedBox(height: 20),
                AuthDivider(label: l10n.orContinueWith),
                const SizedBox(height: 20),
                AuthMethodSwitcher(
                  method: _method,
                  emailLabel: l10n.authEmailTab,
                  phoneLabel: l10n.authPhoneTab,
                  onChanged: (method) => setState(() => _method = method),
                ),
                const SizedBox(height: 18),
                AuthCredentialsFields(
                  method: _method,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  phoneController: _phoneController,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  emailLabel: l10n.email,
                  passwordLabel: l10n.password,
                  passwordHint: l10n.passwordHint,
                  phoneLabel: l10n.phoneNumber,
                  phoneHint: l10n.phoneHint,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _method == AuthInputMethod.phone
                      ? l10n.sendOtp
                      : l10n.createAccount,
                  loading: loading,
                  onPressed: loading ? null : _signUp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
