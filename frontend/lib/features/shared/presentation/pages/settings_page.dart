import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _bookingAlerts = true;
  bool _promotions = false;
  bool _biometricLock = false;

  void _showInfoDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear locally cached images, map tiles, and offline drafts. Your account and booking data will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Temporary cache cleared successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, session) {
        final l10n = context.l10n;
        final cubit = context.read<AppSessionCubit>();
        final theme = Theme.of(context);
        final scheme = context.scheme;

        return AppScaffold(
          title: l10n.settings,
          showBack: true,
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Appearance Section
              _SectionLabel(
                icon: Icons.palette_outlined,
                text: l10n.appearance,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.theme,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how Fixly looks to you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.themeSystem),
                          icon: const Icon(Icons.brightness_auto_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.themeLight),
                          icon: const Icon(Icons.light_mode_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.themeDark),
                          icon: const Icon(Icons.dark_mode_outlined, size: 18),
                        ),
                      ],
                      selected: {session.themeMode},
                      onSelectionChanged: (selected) {
                        cubit.setThemeMode(selected.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.comfortable,
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Language Section
              _SectionLabel(
                icon: Icons.language_rounded,
                text: l10n.language,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.language,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.locale == 'hi'
                                  ? 'हिंदी (Hindi)'
                                  : 'English (US)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.muted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            session.locale.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'en',
                          label: Text('English'),
                          icon: Icon(Icons.translate_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: 'hi',
                          label: Text('हिंदी (Hindi)'),
                          icon: Icon(Icons.translate_rounded, size: 18),
                        ),
                      ],
                      selected: {session.locale},
                      onSelectionChanged: (selected) {
                        cubit.setLocale(selected.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.comfortable,
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Notifications Preferences Section
              _SectionLabel(
                icon: Icons.notifications_none_rounded,
                text: l10n.notificationPreferences,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SettingsCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      title: Text(
                        l10n.pushNotifications,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.pushNotificationsHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      value: session.notificationsEnabled,
                      onChanged: cubit.setNotificationsEnabled,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.mark_chat_unread_outlined,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      title: Text(
                        'Booking Updates',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Get real-time job status and worker arrival alerts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      value: _bookingAlerts,
                      onChanged: (val) => setState(() => _bookingAlerts = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 20,
                          color: scheme.tertiary,
                        ),
                      ),
                      title: Text(
                        'Discounts & Updates',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Receive seasonal offers and platform news',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      value: _promotions,
                      onChanged: (val) => setState(() => _promotions = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Security & Data Section
              _SectionLabel(
                icon: Icons.shield_outlined,
                text: 'Security & Data',
              ),
              const SizedBox(height: AppSpacing.xs),
              _SettingsCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      title: Text(
                        'Biometric App Lock',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Require Face ID or Fingerprint on app open',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      value: _biometricLock,
                      onChanged: (val) => setState(() => _biometricLock = val),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cleaning_services_outlined,
                          size: 20,
                          color: AppColors.warning,
                        ),
                      ),
                      title: Text(
                        'Clear Local Cache',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Free up temporary storage and map cache',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _clearCache(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // About & Legal Section
              _SectionLabel(
                icon: Icons.info_outline_rounded,
                text: 'About & Legal',
              ),
              const SizedBox(height: AppSpacing.xs),
              _SettingsCard(
                child: Column(
                  children: [
                    _SettingsNavTile(
                      icon: Icons.groups_outlined,
                      title: l10n.aboutCooperative,
                      subtitle: 'Learn how Fixly empowers gig workers',
                      onTap: () => _showInfoDialog(
                        context: context,
                        title: l10n.aboutCooperative,
                        content:
                            'Fixly is a worker-owned cooperative platform that connects verified local technicians, electricians, plumbers, and home service professionals directly with customers without high commission middlemen.',
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsNavTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.privacySecurity,
                      subtitle: 'How your data is protected & stored',
                      onTap: () => _showInfoDialog(
                        context: context,
                        title: 'Privacy Policy',
                        content:
                            'Your privacy is strictly respected. Location data is shared only when actively booking or fulfilling a service request. We never sell your personal data.',
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsNavTile(
                      icon: Icons.article_outlined,
                      title: 'Terms of Service',
                      subtitle: 'User agreement and fair wage guarantee',
                      onTap: () => _showInfoDialog(
                        context: context,
                        title: 'Terms of Service',
                        content:
                            'All platform services are provided under the Fair Work & Cooperative Standards. Disputes are handled promptly by our support and safety arbitration team.',
                      ),
                    ),
                    if (kDebugMode) ...[
                      const Divider(height: 1),
                      _SettingsNavTile(
                        icon: Icons.grid_view_rounded,
                        title: l10n.screenGallery,
                        subtitle: 'Developer preview of UI components',
                        iconColor: AppColors.secondary,
                        onTap: () => context.push(RouteNames.demo),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // App Version Branding Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Fixly Platform Cooperative',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.appVersion} • v1.0.4 (Build 2026)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? scheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? scheme.primary,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.muted,
            ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
