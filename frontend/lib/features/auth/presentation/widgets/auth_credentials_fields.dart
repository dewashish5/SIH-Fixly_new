import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import 'auth_screen_layout.dart';

class AuthCredentialsFields extends StatelessWidget {
  const AuthCredentialsFields({
    required this.method,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.emailLabel,
    required this.passwordLabel,
    required this.passwordHint,
    required this.phoneLabel,
    required this.phoneHint,
    super.key,
  });

  final AuthInputMethod method;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String emailLabel;
  final String passwordLabel;
  final String passwordHint;
  final String phoneLabel;
  final String phoneHint;

  static const _duration = Duration(milliseconds: 340);
  static const _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _duration,
      curve: _curve,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: _duration,
        switchInCurve: _curve,
        switchOutCurve: _curve,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: _curve));
          final fade = CurvedAnimation(parent: animation, curve: _curve);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: method == AuthInputMethod.email
            ? _EmailFields(
                key: const ValueKey('email-fields'),
                emailController: emailController,
                passwordController: passwordController,
                obscurePassword: obscurePassword,
                onTogglePassword: onTogglePassword,
                emailLabel: emailLabel,
                passwordLabel: passwordLabel,
                passwordHint: passwordHint,
              )
            : _PhoneField(
                key: const ValueKey('phone-field'),
                phoneController: phoneController,
                phoneLabel: phoneLabel,
                phoneHint: phoneHint,
              ),
      ),
    );
  }
}

class _EmailFields extends StatelessWidget {
  const _EmailFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.emailLabel,
    required this.passwordLabel,
    required this.passwordHint,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String emailLabel;
  final String passwordLabel;
  final String passwordHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: emailController,
          label: emailLabel,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: passwordController,
          label: passwordLabel,
          hint: passwordHint,
          obscureText: obscurePassword,
          validator: (value) =>
              Validators.requiredField(value, label: passwordLabel),
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: onTogglePassword,
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.phoneController,
    required this.phoneLabel,
    required this.phoneHint,
    super.key,
  });

  final TextEditingController phoneController;
  final String phoneLabel;
  final String phoneHint;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: phoneController,
      label: phoneLabel,
      hint: phoneHint,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      validator: Validators.phone,
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+91',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.phone_outlined, size: 20),
          ],
        ),
      ),
    );
  }
}
