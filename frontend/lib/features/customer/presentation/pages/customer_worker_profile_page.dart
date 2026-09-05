import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../workers/data/workers_api_repository.dart';

class CustomerWorkerProfilePage extends StatefulWidget {
  const CustomerWorkerProfilePage({
    required this.workerId,
    this.serviceId,
    super.key,
  });

  final String workerId;
  final String? serviceId;

  @override
  State<CustomerWorkerProfilePage> createState() =>
      _CustomerWorkerProfilePageState();
}

class _CustomerWorkerProfilePageState extends State<CustomerWorkerProfilePage> {
  late final Future<WorkerProfile> _future = WorkersApiRepository().fetchWorker(
    widget.workerId,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkerProfile>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return AppScaffold(
            title: context.l10n.workerProfile,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData) {
          return AppScaffold(
            title: context.l10n.workerProfile,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(snap.error?.toString() ?? 'Worker not found'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Go Back',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          );
        }

        final worker = snap.data!;
        final skillLabel = worker.skills.isEmpty
            ? 'Skilled worker'
            : worker.skills.join(' • ');
        final aboutSkill = worker.skills.isEmpty
            ? 'professional'
            : worker.skills.first.toLowerCase();
        final hasRatingHistory =
            worker.jobsCompleted > 0 || worker.reviewCount > 0;
        final kycLabel = switch (worker.kycStatus?.toLowerCase()) {
          'approved' => 'Identity verified',
          'submitted' || 'pending' || 'in_review' => 'Identity under review',
          _ => worker.isVerified ? 'Profile verified' : 'Verification pending',
        };

        return AppScaffold(
          title: context.l10n.workerProfile,
          body: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0] : 'W',
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
                      const Icon(Icons.verified, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      worker.isOnline ? Icons.circle : Icons.circle_outlined,
                      size: 10,
                      color: worker.isOnline
                          ? AppColors.success
                          : AppColors.outline,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      worker.isOnline ? 'Online now' : 'Currently offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: worker.isOnline
                            ? AppColors.success
                            : AppColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  worker.title?.isNotEmpty == true
                      ? '${worker.title} • $skillLabel'
                      : skillLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip(
                      label: 'Rating',
                      value: hasRatingHistory && worker.rating > 0
                          ? worker.rating.toStringAsFixed(1)
                          : 'N/A',
                      icon: Icons.star,
                    ),
                    _StatChip(
                      label: 'Jobs',
                      value: '${worker.jobsCompleted}',
                      icon: Icons.work,
                    ),
                    _StatChip(
                      label: 'Reliability',
                      value: worker.jobsCompleted > 0
                          ? '${worker.reliabilityScore}%'
                          : 'Limited',
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
                        'Trust & Reliability',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _TrustRow(label: 'Verification', value: kycLabel),
                      _TrustRow(
                        label: 'Email',
                        value: worker.isEmailVerified
                            ? 'Verified'
                            : 'Not verified',
                      ),
                      _TrustRow(
                        label: 'Completed jobs',
                        value: worker.jobsCompleted == 0
                            ? 'No completed jobs yet'
                            : '${worker.jobsCompleted}',
                      ),
                      _TrustRow(
                        label: 'On-time arrival',
                        value: worker.jobsCompleted == 0
                            ? 'Not enough data'
                            : _percent(worker.onTimeArrival),
                      ),
                      _TrustRow(
                        label: 'Completion rate',
                        value: worker.jobsCompleted == 0
                            ? 'Not enough data'
                            : _percent(worker.completionRate),
                      ),
                      if (worker.serviceRadiusKm != null)
                        _TrustRow(
                          label: 'Service radius',
                          value:
                              '${worker.serviceRadiusKm!.toStringAsFixed(0)} km',
                        ),
                      const SizedBox(height: 4),
                      Text(
                        worker.jobsCompleted == 0
                            ? 'This worker is new to the platform. Reliability metrics will appear after completed jobs.'
                            : 'Based on completed jobs and customer activity.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.outline,
                        ),
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
                        'About',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        worker.bio?.isNotEmpty == true
                            ? worker.bio!
                            : worker.jobsCompleted > 0
                            ? 'Experienced $aboutSkill with ${worker.jobsCompleted} completed jobs.'
                            : 'A $aboutSkill professional new to the Fixly platform.',
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
                      if (!hasRatingHistory)
                        const Text('No rating available for this worker.')
                      else if (worker.reviews.isEmpty)
                        Text(
                          worker.reviewCount > 0
                              ? '${worker.reviewCount} ratings, but no written reviews yet.'
                              : 'No written reviews yet.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        ...worker.reviews
                            .take(5)
                            .map(
                              (review) => _ReviewTile(
                                name: review.reviewerName,
                                rating: review.rating,
                                text: review.comment.isEmpty
                                    ? 'No written comment.'
                                    : review.comment,
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AccentButton(
                  label: 'Book This Worker',
                  onPressed: () => context.push(
                    '${RouteNames.customerBooking}?workerId=${worker.id}'
                    '&serviceId=${Uri.encodeComponent(widget.serviceId ?? '')}'
                    '&category=${Uri.encodeComponent(worker.category ?? '')}',
                  ),
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
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _percent(double? value) =>
    value == null ? 'Not enough data' : '${value.toStringAsFixed(0)}%';

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.name,
    required this.rating,
    required this.text,
  });

  final String name;
  final double rating;
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
                rating.round(),
                (_) =>
                    const Icon(Icons.star, size: 14, color: AppColors.tertiary),
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
