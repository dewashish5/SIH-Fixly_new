import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../workers/data/workers_api_repository.dart';

class CustomerWorkersPage extends StatefulWidget {
  const CustomerWorkersPage({super.key});

  @override
  State<CustomerWorkersPage> createState() => _CustomerWorkersPageState();
}

class _CustomerWorkersPageState extends State<CustomerWorkersPage> {
  late Future<List<WorkerProfile>> _future =
      WorkersApiRepository().fetchNearby();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.availableWorkers,
      body: FutureBuilder<List<WorkerProfile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snap.error.toString()),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Retry',
                    onPressed: () => setState(() {
                      _future = WorkersApiRepository().fetchNearby();
                    }),
                  ),
                ],
              ),
            );
          }
          final workers = snap.data ?? const [];
          if (workers.isEmpty) {
            return Center(
              child: Text(
                'No workers nearby yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${workers.length} verified workers nearby',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return _WorkerListTile(
                      worker: worker,
                      onTap: () =>
                          context.push('/customer/worker/${worker.id}'),
                    ).appListEnter(
                      context,
                      index: index,
                      id: worker.id,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkerListTile extends StatelessWidget {
  const _WorkerListTile({
    required this.worker,
    required this.onTap,
  });

  final WorkerProfile worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                worker.name.isNotEmpty ? worker.name[0] : 'W',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.skills.isEmpty
                        ? 'Skilled worker'
                        : worker.skills.take(3).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.accent),
                      Text(' ${worker.rating}'),
                      const SizedBox(width: 12),
                      Text('${worker.jobsCompleted} jobs'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
