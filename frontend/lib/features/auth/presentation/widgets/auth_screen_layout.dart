import 'package:flutter/material.dart';
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
            foregroundColor: AppColors.primary,
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
