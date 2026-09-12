import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/worker_dashboard_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerAvailabilityStatusPage extends StatefulWidget {
  const WorkerAvailabilityStatusPage({super.key});

  @override
  State<WorkerAvailabilityStatusPage> createState() =>
      _WorkerAvailabilityStatusPageState();
}

class _WorkerAvailabilityStatusPageState
    extends State<WorkerAvailabilityStatusPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkerDashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerDashboardCubit, WorkerDashboardState>(
      builder: (context, state) {
        return AppScaffold(
          title: context.l10n.availabilityStatus,
          body: AppRefreshIndicator(
            onRefresh: () => context.read<WorkerDashboardCubit>().load(),
            child: ListView(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isAvailable
                              ? AppColors.success
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isAvailable ? 'Online' : 'Offline',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              state.isAvailable
                                  ? 'Receiving nearby job requests'
                                  : 'Not receiving job requests',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.isAvailable,
                        activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                        thumbColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.success
                              : null,
                        ),
                        onChanged: (_) => context
                            .read<WorkerDashboardCubit>()
                            .toggleAvailability(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mon–Fri: 9 AM – 6 PM'),
                      SizedBox(height: 8),
                      Text('Sat–Sun: 10 AM – 4 PM'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
