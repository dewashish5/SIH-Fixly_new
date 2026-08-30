import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../cubit/worker_dashboard_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkerDashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName =
        MockRepository.instance.currentUser?.name ?? l10n.guestUser;

    return BlocBuilder<WorkerDashboardCubit, WorkerDashboardState>(
      builder: (context, state) {
        return AppScaffold(
          titleWidget: GreetingAppBarTitle(userName: userName),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(RouteNames.sharedNotifications),
            ),
          ],
          body: state.status == WorkerDashboardStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Today',
                            value: '₹${state.todayEarnings.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Jobs done',
                            value: '${state.completedJobs}',
                            icon: Icons.work_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Reliability',
                            value: '${state.reliabilityScore}%',
                            icon: Icons.verified_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Incoming',
                            value: '${state.incomingCount}',
                            icon: Icons.inbox_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for jobs'),
                      subtitle: Text(
                        state.isAvailable ? 'You are online' : 'You are offline',
                      ),
                      value: state.isAvailable,
                      activeTrackColor: AppColors.secondary.withValues(alpha: 0.4),
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.secondary
                            : null,
                      ),
                      onChanged: (_) =>
                          context.read<WorkerDashboardCubit>().toggleAvailability(),
                    ),
                    if (state.activeJob != null) ...[
                      const SizedBox(height: 16),
                      Text('Active job', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      JobListTile(
                        title: state.activeJob!.title,
                        subtitle: state.activeJob!.customerName,
                        pay: state.activeJob!.pay,
                        distanceKm: state.activeJob!.distanceKm,
                        onTap: () => context.push(RouteNames.workerActiveJob),
                      ),
                    ],
                    const Spacer(),
                    PrimaryButton(
                      label: 'View job feed',
                      onPressed: () => context.push(RouteNames.workerJobs),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'My profile',
                      onPressed: () => context.go(RouteNames.workerProfileTab),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
