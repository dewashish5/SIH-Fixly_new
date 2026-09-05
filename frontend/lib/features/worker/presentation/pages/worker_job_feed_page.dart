import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../cubit/job_feed_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerJobFeedPage extends StatefulWidget {
  const WorkerJobFeedPage({super.key});

  @override
  State<WorkerJobFeedPage> createState() => _WorkerJobFeedPageState();
}

class _WorkerJobFeedPageState extends State<WorkerJobFeedPage> {
  @override
  void initState() {
    super.initState();
    context.read<JobFeedCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobFeedCubit, JobFeedState>(
      builder: (context, state) {
        return AppScaffold(
          title: context.l10n.jobFeed,
          showBack: false,
          body: state.status == JobFeedStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: AppRefreshIndicator(
                        onRefresh: () => context.read<JobFeedCubit>().load(),
                        child: ListView.separated(
                          physics: appRefreshScrollPhysics,
                          itemCount: state.jobs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final job = state.jobs[index];
                            return JobListTile(
                            title: job.title,
                            subtitle:
                                '${job.customerName} • ${_jobStatus(job.status)}',
                            pay: job.pay,
                            distanceKm: job.distanceKm,
                            onTap: () => context.push(
                              RouteNames.workerJobDetail.replaceFirst(
                                ':id',
                                job.id,
                              ),
                            ),
                          ).appListEnter(context, index: index, id: job.id);
                        },
                      ),
                    ),
                  ),
                ],
                ),
        );
      },
    );
  }
}

String _jobStatus(JobStatus status) {
  switch (status) {
    case JobStatus.incoming:
      return 'Incoming';
    case JobStatus.active:
      return 'Active';
    case JobStatus.completed:
      return 'Completed';
  }
}
