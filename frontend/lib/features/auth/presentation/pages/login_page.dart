import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/app_session_cubit.dart';
import '../widgets/auth_credentials_fields.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loading = state.status == AppSessionStatus.loading;

        return AuthScreenLayout(
          title: l10n.login,
          subtitle: l10n.loginSubtitle,
          showBack: false,
          footer: Column(
            children: [
              AuthWorkerChip(
                label: l10n.signInAsWorker,
                active: _workerMode,
                onTap: _toggleWorkerMode,
              ),
              const SizedBox(height: 12),
              AuthLinkRow(
                prompt: l10n.dontHaveAccount,
                actionLabel: l10n.signUp,
                onTap: () => context.push(RouteNames.signup),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthSocialRow(
                  onGoogle:
                      loading ? null : () => _handleSocial(_cubit.signInWithGoogle),
                ),
                const SizedBox(height: 20),
                AuthDivider(label: l10n.orContinueWith),
                const SizedBox(height: 20),
                AuthCredentialsFields(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  emailLabel: l10n.email,
                  passwordLabel: l10n.password,
                  passwordHint: l10n.passwordHint,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l10n.login,
                  loading: loading,
                  onPressed: loading ? null : _login,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
