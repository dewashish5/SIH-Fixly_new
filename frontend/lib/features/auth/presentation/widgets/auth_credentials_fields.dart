import 'package:flutter/material.dart';

import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';

class AuthCredentialsFields extends StatelessWidget {
  const AuthCredentialsFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.emailLabel,
    required this.passwordLabel,
    required this.passwordHint,
    this.nameController,
    this.nameLabel,
    this.nameHint,
    this.phoneController,
    this.phoneLabel,
    this.phoneHint,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String emailLabel;
  final String passwordLabel;
  final String passwordHint;
  final TextEditingController? nameController;
  final String? nameLabel;
  final String? nameHint;
  final TextEditingController? phoneController;
  final String? phoneLabel;
  final String? phoneHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (nameController != null) ...[
          AppTextField(
            controller: nameController!,
            label: nameLabel ?? context.l10n.fullName,
            hint: nameHint ?? context.l10n.fullNameHint,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                Validators.requiredField(value, label: nameLabel ?? 'Name'),
          ),
          const SizedBox(height: 14),
        ],
        if (phoneController != null) ...[
          AppTextField(
            controller: phoneController!,
            label: phoneLabel ?? context.l10n.phoneNumber,
            hint: phoneHint ?? context.l10n.phoneHint,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: Validators.phone,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.phone_outlined, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
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
            tooltip: obscurePassword
                ? context.l10n.showPassword
                : context.l10n.hidePassword,
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
