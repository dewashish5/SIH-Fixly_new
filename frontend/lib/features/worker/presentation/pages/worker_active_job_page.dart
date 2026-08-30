import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../cubit/active_job_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerActiveJobPage extends StatefulWidget {
  const WorkerActiveJobPage({super.key});

  @override
  State<WorkerActiveJobPage> createState() => _WorkerActiveJobPageState();
}

class _WorkerActiveJobPageState extends State<WorkerActiveJobPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActiveJobCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveJobCubit, ActiveJobState>(
      builder: (context, state) {
        final job = state.job;

        return AppScaffold(
          title: context.l10n.activeJob,
          body: state.status == ActiveJobStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : job == null
                  ? const Center(child: Text('No active job'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StatusBadge(
                          label: state.status == ActiveJobStatus.completed
                              ? 'Completed'
                              : 'In progress',
                          color: state.status == ActiveJobStatus.completed
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(job.customerName),
                        const SizedBox(height: 16),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.address),
                              const SizedBox(height: 8),
                              Text(
                                '₹${job.pay.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (state.status != ActiveJobStatus.completed) ...[
                          PrimaryButton(
                            label: 'Navigate',
                            onPressed: () =>
                                context.push(RouteNames.workerNavigation),
                          ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Mark complete',
                            onPressed: () =>
                                context.read<ActiveJobCubit>().completeJob(),
                          ),
                        ] else
                          PrimaryButton(
                            label: 'Back to dashboard',
                            onPressed: () =>
                                context.go(RouteNames.workerDashboard),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}
