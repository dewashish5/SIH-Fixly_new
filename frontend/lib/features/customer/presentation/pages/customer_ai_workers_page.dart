import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerAiWorkersPage extends StatelessWidget {
  const CustomerAiWorkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workers = MockRepository.instance.workers;

    return AppScaffold(
      title: context.l10n.aiMatchedWorkers,
      body: ListView.builder(
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          final matchScore = 98 - (index * 4);
          return _AiWorkerTile(
            worker: worker,
            matchScore: matchScore,
            onTap: () => context.push('/customer/worker/${worker.id}'),
          );
        },
      ),
    );
  }
}

class _AiWorkerTile extends StatelessWidget {
  const _AiWorkerTile({
    required this.worker,
    required this.matchScore,
    required this.onTap,
  });

  final WorkerProfile worker;
  final int matchScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Stack(
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
                if (worker.insured)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(worker.skills.join(' • ')),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.tertiary),
                      Text(' ${worker.rating}'),
                      const SizedBox(width: 8),
                      Text('${worker.jobsCompleted} jobs'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$matchScore%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('match', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
