import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, session) {
        final l10n = context.l10n;
        return AppScaffold(
          title: l10n.settings,
          body: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hindiLanguage),
                value: session.locale == 'hi',
                onChanged: (value) {
                  context.read<AppSessionCubit>().setLocale(value ? 'hi' : 'en');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? l10n.languageHindi : l10n.languageEnglish,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.notificationPreferences),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.sharedNotifications),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security_outlined),
                title: Text(l10n.privacySecurity),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutCooperative),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              if (kDebugMode)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.grid_view_rounded),
                  title: Text(l10n.screenGallery),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.demo),
                ),
              const Spacer(),
              SecondaryButton(
                label: l10n.emergencySos,
                onPressed: () => context.push(RouteNames.sharedSos),
              ),
            ],
          ),
        );
      },
    );
  }
}
