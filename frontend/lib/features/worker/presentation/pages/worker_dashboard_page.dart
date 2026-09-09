import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/worker_realtime_service.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
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
    final userName = context.select(
      (WorkerDashboardCubit c) =>
          c.state.workerName.isEmpty ? l10n.guestUser : c.state.workerName,
    );

    return BlocBuilder<WorkerDashboardCubit, WorkerDashboardState>(
      builder: (context, state) {
        return AppScaffold(
          titleWidget: GreetingAppBarTitle(userName: userName),
          showBack: false,
          actions: [
            StreamBuilder<bool>(
              stream: WorkerRealtimeService.instance.connectionStream,
              initialData: WorkerRealtimeService.instance.isConnected,
              builder: (context, snapshot) {
                final isLive = snapshot.data ?? false;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLive ? const Color(0xFF10B981) : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLive ? 'LIVE' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLive ? const Color(0xFF10B981) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.sos, color: Colors.red),
              tooltip: 'Emergency SOS',
              onPressed: () => context.push(RouteNames.sharedSos),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: l10n.notifications,
              onPressed: () => context.push(RouteNames.sharedNotifications),
            ),
          ],
          body: AppRefreshIndicator(
            onRefresh: () => context.read<WorkerDashboardCubit>().load(),
            child: state.status == WorkerDashboardStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    physics: appRefreshScrollPhysics,
                    children: [
                      Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Today',
                            value: '₹${state.todayEarnings.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                            index: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Jobs done',
                            value: '${state.completedJobs}',
                            icon: Icons.work_outline,
                            index: 1,
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
                            index: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Incoming',
                            value: '${state.incomingCount}',
                            icon: Icons.inbox_outlined,
                            index: 3,
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
                      activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.success
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
                      ).appListEnter(
                        context,
                        index: 0,
                        id: state.activeJob!.id,
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'View job feed',
                      onPressed: () => context.push(RouteNames.workerJobs),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'My profile',
                      onPressed: () => context.go(RouteNames.workerProfileTab),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
    required this.index,
  });

  final String label;
  final String value;
  final IconData icon;
  final int index;

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
    ).appListEnter(context, index: index, id: label);
  }
}
