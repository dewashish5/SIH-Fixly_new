import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/network/worker_realtime_service.dart';
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
          actions: [
            StreamBuilder<bool>(
              stream: WorkerRealtimeService.instance.connectionStream,
              initialData: WorkerRealtimeService.instance.isConnected,
              builder: (context, snapshot) {
                final isLive = snapshot.data ?? false;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
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
          ],
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
