import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/app_session_cubit.dart';
import '../widgets/auth_screen_layout.dart';

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
  bool _workerMode = false;

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
    final success = await signIn();
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
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _cubit.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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
    context.go(_cubit.postAuthRoute());
  }

  void _toggleWorkerMode() {
    setState(() => _workerMode = !_workerMode);
    _cubit.setRole(_workerMode ? 'worker' : 'customer');
    if (_workerMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signInAsWorkerHint)),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (Validators.email(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forgotPasswordHint)),
      );
      return;
    }
    try {
      await _cubit.requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forgotPasswordSent)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forgotPasswordSent)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loading = state.status == AppSessionStatus.loading;

        return AuthCurvedShell(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthPageTitle(l10n.login),
                const SizedBox(height: 28),
                AuthUnderlineField(
                  controller: _emailController,
                  label: l10n.username,
                  hint: l10n.usernameHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 28),
                AuthUnderlineField(
                  controller: _passwordController,
                  label: l10n.password,
                  hint: l10n.passwordHint,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!loading) _login();
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
                      color: context.muted,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AuthDarkButton(
                  label: l10n.signIn,
                  loading: loading,
                  onPressed: loading ? null : _login,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: context.ink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
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
                const SizedBox(height: 20),
                AuthGoogleSquare(
                  onPressed: loading
                      ? null
                      : () => _handleSocial(_cubit.signInWithGoogle),
                ),
                const SizedBox(height: 28),
                AuthWorkerChip(
                  label: l10n.signInAsWorker,
                  active: _workerMode,
                  onTap: _toggleWorkerMode,
                ),
                const SizedBox(height: 8),
                AuthLinkRow(
                  prompt: l10n.dontHaveAccount,
                  actionLabel: l10n.signUp,
                  onTap: () => context.push(RouteNames.signup),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
