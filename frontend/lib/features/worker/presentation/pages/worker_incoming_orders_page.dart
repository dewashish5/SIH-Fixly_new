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

class WorkerIncomingOrdersPage extends StatefulWidget {
  const WorkerIncomingOrdersPage({super.key});

  @override
  State<WorkerIncomingOrdersPage> createState() =>
      _WorkerIncomingOrdersPageState();
}

class _WorkerIncomingOrdersPageState extends State<WorkerIncomingOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<JobFeedCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobFeedCubit, JobFeedState>(
      builder: (context, state) {
        final incoming = state.jobs
            .where((j) => j.status == JobStatus.incoming)
            .toList();

        return AppScaffold(
          title: context.l10n.incomingOrders,
          body: state.status == JobFeedStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (incoming.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No incoming orders',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: incoming.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final job = incoming[index];
                            return JobListTile(
                              title: job.title,
                              subtitle: job.address,
                              pay: job.pay,
                              distanceKm: job.distanceKm,
                              onTap: () => context.push(
                                RouteNames.workerJobDetail
                                    .replaceFirst(':id', job.id),
                              ),
                            ).appListEnter(
                              context,
                              index: index,
                              id: job.id,
                            );
                          },
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
