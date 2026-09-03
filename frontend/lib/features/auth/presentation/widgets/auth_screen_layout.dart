import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';

class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final canPop =
        showBack && (ModalRoute.of(context)?.canPop ?? false);

    return Scaffold(
      backgroundColor: context.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canPop)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: context.l10n.goBack,
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.muted,
                            height: 1.4,
                          ),
                    ).animate().fadeIn(delay: 60.ms, duration: 280.ms),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.hairline.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.scheme.primary.withValues(
                              alpha: context.isDark ? 0.12 : 0.06,
                            ),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: child,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 320.ms)
                        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                    if (footer != null) ...[
                      const SizedBox(height: 20),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({
    required this.onGoogle,
    super.key,
  });

  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    return _SocialTag(
      asset: 'assets/icons/google.svg',
      semanticLabel: 'Google',
      onPressed: onGoogle,
    );
  }
}

class _SocialTag extends StatelessWidget {
  const _SocialTag({
    required this.asset,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: context.canvas,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.hairline),
            ),
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthRoleSelector extends StatelessWidget {
  const AuthRoleSelector({
    required this.selectedRole,
    required this.customerLabel,
    required this.workerLabel,
    required this.customerSubtitle,
    required this.workerSubtitle,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String selectedRole;
  final String customerLabel;
  final String workerLabel;
  final String customerSubtitle;
  final String workerSubtitle;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.chooseRole,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RoleTile(
                icon: Icons.home_repair_service_outlined,
                label: customerLabel,
                subtitle: customerSubtitle,
                selected: selectedRole == 'customer',
                onTap: enabled ? () => onChanged('customer') : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleTile(
                icon: Icons.engineering_outlined,
                label: workerLabel,
                subtitle: workerSubtitle,
                selected: selectedRole == 'worker',
                onTap: enabled ? () => onChanged('worker') : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected
            ? context.scheme.primary.withValues(alpha: context.isDark ? 0.18 : 0.06)
            : context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? context.scheme.primary : context.hairline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? context.scheme.primary.withValues(alpha: 0.16)
                        : context.scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? context.scheme.primary : context.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.muted,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.muted,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
    super.key,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.muted,
              ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor:
                context.isDark ? Colors.white : AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class AuthWorkerChip extends StatelessWidget {
  const AuthWorkerChip({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.success.withValues(alpha: context.isDark ? 0.18 : 0.1)
          : context.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.success : context.hairline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.engineering_outlined,
                color: active ? AppColors.success : context.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.success : context.ink,
                      ),
                ),
              ),
              Icon(
                active ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: active ? AppColors.success : context.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared curved auth shell (login / signup).
class AuthCurvedShell extends StatelessWidget {
  const AuthCurvedShell({
    required this.child,
    this.compact = false,
    this.scrollable = true,
    super.key,
  });

  final Widget child;
  final bool compact;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final topPad = MediaQuery.paddingOf(context).top;
    final l10n = context.l10n;
    final headerExtra = compact ? 156.0 : 236.0;
    final iconSize = compact ? 80.0 : 96.0;
    final curve = compact ? 60.0 : 72.0;
    final pad = compact
        ? const EdgeInsets.fromLTRB(26, 26, 26, 16)
        : const EdgeInsets.fromLTRB(28, 40, 28, 28);

    final body = scrollable
        ? SingleChildScrollView(padding: pad, child: child)
        : Padding(
            padding: pad,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: child,
                  ),
                );
              },
            ),
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        resizeToAvoidBottomInset: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: topPad + headerExtra,
              child: ColoredBox(
                color: AppColors.primaryDark,
                child: Padding(
                  padding: EdgeInsets.only(left: 28, right: 28, top: topPad),
                  child: Align(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(compact ? 18 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: compact ? 16 : 20,
                            offset: Offset(0, compact ? 8 : 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(compact ? 18 : 20),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.cover,
                          semanticLabel: l10n.appName,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.primaryDark,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(curve),
                      topRight: Radius.circular(curve),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(curve),
                      topRight: Radius.circular(curve),
                    ),
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPageTitle extends StatelessWidget {
  const AuthPageTitle(this.title, {this.compact = false, super.key});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final base = compact
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.headlineLarge;
    return Text(
      title,
      style: base?.copyWith(
        color: context.isDark ? Colors.white : AppColors.primaryDark,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
    );
  }
}

/// Compact customer/worker toggle (no long subtitles).
class AuthRoleToggle extends StatelessWidget {
  const AuthRoleToggle({
    required this.selectedRole,
    required this.customerLabel,
    required this.workerLabel,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String selectedRole;
  final String customerLabel;
  final String workerLabel;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: _RoleChip(
              label: customerLabel,
              selected: selectedRole == 'customer',
              onTap: enabled ? () => onChanged('customer') : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RoleChip(
              label: workerLabel,
              selected: selectedRole == 'worker',
              onTap: enabled ? () => onChanged('worker') : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.scheme.primary.withValues(alpha: context.isDark ? 0.22 : 0.1)
          : context.scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.scheme.primary : context.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? context.scheme.primary : context.ink,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthUnderlineField extends StatelessWidget {
  const AuthUnderlineField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffix,
    this.prefix,
    this.maxLength,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.dense = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefix;
  final int? maxLength;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final baseBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: context.hairline, width: 1.2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.ink,
                fontSize: dense ? 12.5 : null,
                height: 1.25,
              ),
        ),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          validator: validator,
          maxLength: maxLength,
          onFieldSubmitted: onFieldSubmitted,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.ink,
                fontSize: dense ? 15 : null,
                height: 1.35,
              ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: maxLength == null ? null : '',
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.muted,
                  fontSize: dense ? 14.5 : null,
                  height: 1.35,
                ),
            border: baseBorder,
            enabledBorder: baseBorder,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.scheme.primary, width: 1.8),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.scheme.error, width: 1.2),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.scheme.error, width: 1.8),
            ),
            // Balanced vertical padding so text sits near underline, not floating up.
            contentPadding: EdgeInsets.only(
              top: dense ? 8 : 10,
              bottom: dense ? 10 : 10,
            ),
            // prefixIcon stays visible even when empty/unfocused (unlike prefix).
            prefixIcon: prefix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 0, right: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: prefix,
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 36,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class AuthDarkButton extends StatelessWidget {
  const AuthDarkButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 46.0 : 48.0;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          elevation: 0,
          minimumSize: Size.fromHeight(h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 14 : 15,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthGoogleSquare extends StatelessWidget {
  const AuthGoogleSquare({
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 48.0 : 56.0;
    return Semantics(
      button: true,
      label: context.l10n.continueWithGoogle,
      child: Material(
        color: context.scheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.hairline, width: 1.2),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/google.svg',
                width: compact ? 22 : 26,
                height: compact ? 22 : 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
