import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/app_session_cubit.dart';
import '../widgets/auth_screen_layout.dart';
import '../../../../core/utils/toast_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailSubmitting = false;
  bool _googleSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AppSessionCubit>();
    cubit.setAuthFlow(AuthFlow.login);
    cubit.setRole('customer');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AppSessionCubit get _cubit => context.read<AppSessionCubit>();

  Future<void> _handleSocial(Future<bool> Function() signIn) async {
    if (_googleSubmitting || _emailSubmitting) return;
    setState(() => _googleSubmitting = true);
    try {
      final success = await signIn();
      if (!mounted || !success) {
        final msg = _cubit.state.errorMessage;
        if (mounted && msg != null) {
          ToastUtils.showError(context: context, message: msg);
        }
        return;
      }
      context.go(_cubit.postAuthRoute());
    } finally {
      if (mounted) setState(() => _googleSubmitting = false);
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus(); // dismiss keyboard instantly
    if (!_formKey.currentState!.validate()) return;
    if (_emailSubmitting || _googleSubmitting) return;
    setState(() => _emailSubmitting = true);
    try {
      final success = await _cubit.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (!success) {
        final msg = _cubit.state.errorMessage;
        if (msg != null) {
          ToastUtils.showError(context: context, message: msg);
        }
        return;
      }
      context.go(_cubit.postAuthRoute());
    } finally {
      if (mounted) setState(() => _emailSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (Validators.email(email) != null) {
      ToastUtils.showToast(context: context, message: l10n.forgotPasswordHint);
      return;
    }
    try {
      await _cubit.requestPasswordReset(email);
      if (!mounted) return;
      ToastUtils.showToast(context: context, message: l10n.forgotPasswordSent);
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showToast(context: context, message: l10n.forgotPasswordSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final cubitLoading = state.status == AppSessionStatus.loading;
        final emailLoading = _emailSubmitting || (cubitLoading && !_googleSubmitting);
        final googleLoading = _googleSubmitting || (cubitLoading && _googleSubmitting);
        final isBusy = emailLoading || googleLoading;

        return AuthCurvedShell(
          footer: AuthLinkRow(
            prompt: l10n.dontHaveAccount,
            actionLabel: l10n.signUp,
            onTap: () => context.push(RouteNames.signup),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthPageTitle(l10n.login),
                const SizedBox(height: 20),
                AuthUnderlineField(
                  controller: _emailController,
                  label: l10n.username,
                  hint: l10n.usernameHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 18),
                AuthUnderlineField(
                  controller: _passwordController,
                  label: l10n.password,
                  hint: l10n.passwordHint,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!isBusy) _login();
                  },
                  validator: (value) =>
                      Validators.requiredField(value, label: l10n.password),
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.ink.withValues(alpha: 0.55),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 20),
                AuthDarkButton(
                  label: l10n.signIn,
                  loading: emailLoading,
                  onPressed: isBusy ? null : _login,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isBusy ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: context.scheme.primary,
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                const SizedBox(height: 12),
                AuthGoogleSquare(
                  loading: googleLoading,
                  onPressed: isBusy
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
