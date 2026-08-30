import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerWorkersPage extends StatelessWidget {
  const CustomerWorkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workers = MockRepository.instance.workers;

    return AppScaffold(
      title: context.l10n.availableWorkers,
      body: Column(
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
                  index: index,
                  onTap: () =>
                      context.push('/customer/worker/${worker.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerListTile extends StatelessWidget {
  const _WorkerListTile({
    required this.worker,
    required this.index,
    required this.onTap,
  });

  final WorkerProfile worker;
  final int index;
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
                worker.name[0],
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
                  Row(
                    children: [
                      Text(
                        worker.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (worker.insured) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            size: 16, color: AppColors.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(worker.skills.join(' • ')),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.tertiary),
                      Text(' ${worker.rating}'),
                      const SizedBox(width: 12),
                      Text('${worker.reliabilityScore}% reliable'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.05);
  }
}
