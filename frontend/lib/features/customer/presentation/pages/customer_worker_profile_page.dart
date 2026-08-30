import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerWorkerProfilePage extends StatelessWidget {
  const CustomerWorkerProfilePage({required this.workerId, super.key});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    final worker = MockRepository.instance.workerById(workerId);

    if (worker == null) {
      return AppScaffold(
        title: context.l10n.workerProfile,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Worker not found'),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Go Back', onPressed: () => context.pop()),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: context.l10n.workerProfile,
      body: SingleChildScrollView(
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                worker.name[0],
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ).animate().scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  worker.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (worker.insured) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: AppColors.secondary),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              worker.skills.join(' • '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  label: 'Rating',
                  value: '${worker.rating}',
                  icon: Icons.star,
                ),
                _StatChip(
                  label: 'Jobs',
                  value: '${worker.jobsCompleted}',
                  icon: Icons.work,
                ),
                _StatChip(
                  label: 'Reliability',
                  value: '${worker.reliabilityScore}%',
                  icon: Icons.trending_up,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experienced ${worker.skills.first.toLowerCase()} with ${worker.jobsCompleted}+ completed jobs. Known for quality work and punctuality.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Reviews',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ReviewTile(
                    name: 'Priya S.',
                    rating: 5,
                    text: 'Excellent work, very professional!',
                  ),
                  _ReviewTile(
                    name: 'Rahul V.',
                    rating: 4,
                    text: 'Good service, arrived on time.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Book This Worker',
              onPressed: () => context.push(RouteNames.customerBooking),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.name,
    required this.rating,
    required this.text,
  });

  final String name;
  final int rating;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              ...List.generate(
                rating,
                (_) => const Icon(Icons.star, size: 14, color: AppColors.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
