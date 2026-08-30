import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../cubit/profile_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class ProfileHubPage extends StatefulWidget {
  const ProfileHubPage({super.key});

  @override
  State<ProfileHubPage> createState() => _ProfileHubPageState();
}

class _ProfileHubPageState extends State<ProfileHubPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return AppScaffold(
          title: l10n.profile,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceContainer,
                      child: Text(
                        state.name.isNotEmpty ? state.name[0] : '?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(state.phone),
                          if (state.insured) ...[
                            const SizedBox(height: 8),
                            const InsuranceBadge(compact: true),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _HubTile(
                icon: Icons.edit_outlined,
                label: l10n.editProfile,
                onTap: () => context.push(RouteNames.sharedEditProfile),
              ),
              _HubTile(
                icon: Icons.settings_outlined,
                label: l10n.settings,
                onTap: () => context.push(RouteNames.sharedSettings),
              ),
              _HubTile(
                icon: Icons.history,
                label: l10n.orderHistory,
                onTap: () => context.push(RouteNames.sharedOrderHistory),
              ),
              _HubTile(
                icon: Icons.notifications_outlined,
                label: l10n.notifications,
                onTap: () => context.push(RouteNames.sharedNotifications),
              ),
              _HubTile(
                icon: Icons.support_agent_outlined,
                label: l10n.support,
                onTap: () => context.push(RouteNames.sharedSupportChat),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
