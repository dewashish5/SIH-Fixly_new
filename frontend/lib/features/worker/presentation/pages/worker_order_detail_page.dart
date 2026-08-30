import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../cubit/job_feed_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerOrderDetailPage extends StatelessWidget {
  const WorkerOrderDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final job = MockRepository.instance.jobById(jobId);

    if (job == null) {
      return AppScaffold(
        title: context.l10n.orderDetails,
        body: const Center(child: Text('Job not found')),
      );
    }

    return AppScaffold(
      title: context.l10n.orderDetails,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(job.customerName, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(icon: Icons.location_on_outlined, text: job.address),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.social_distance,
                  text: '${job.distanceKm.toStringAsFixed(1)} km away',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.currency_rupee,
                  text: '₹${job.pay.toStringAsFixed(0)} payout',
                  valueColor: AppColors.accent,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (job.status == JobStatus.incoming)
            PrimaryButton(
              label: 'Accept job',
              onPressed: () async {
                await context.read<JobFeedCubit>().acceptJob(job.id);
                if (context.mounted) {
                  context.go(RouteNames.workerActiveJob);
                }
              },
            )
          else
            SecondaryButton(
              label: 'View active job',
              onPressed: () => context.push(RouteNames.workerActiveJob),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    this.valueColor,
  });

  final IconData icon;
  final String text;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.w600 : null,
                ),
          ),
        ),
      ],
    );
  }
}
