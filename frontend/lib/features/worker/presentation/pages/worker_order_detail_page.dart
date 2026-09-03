import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../cubit/job_feed_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerOrderDetailPage extends StatefulWidget {
  const WorkerOrderDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  State<WorkerOrderDetailPage> createState() => _WorkerOrderDetailPageState();
}

class _WorkerOrderDetailPageState extends State<WorkerOrderDetailPage> {
  WorkerJob? _job;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final fromFeed = context.read<JobFeedCubit>().jobById(widget.jobId);
    if (fromFeed != null) {
      setState(() {
        _job = fromFeed;
        _loading = false;
      });
      return;
    }
    try {
      final job = await BookingsApiRepository().workerJobById(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: context.l10n.orderDetails,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final job = _job;
    if (job == null) {
      return AppScaffold(
        title: context.l10n.orderDetails,
        body: Center(child: Text(_error ?? 'Job not found')),
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
                  icon: Icons.currency_rupee,
                  text: '₹${job.pay.toStringAsFixed(0)} payout',
                  valueColor: AppColors.accent,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (job.status == JobStatus.incoming) ...[
            PrimaryButton(
              label: 'Accept job',
              onPressed: () async {
                await context.read<JobFeedCubit>().acceptJob(job.id);
                if (context.mounted) {
                  context.go(RouteNames.workerActiveJob);
                }
              },
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Decline',
              onPressed: () async {
                await context.read<JobFeedCubit>().declineJob(job.id);
                if (context.mounted) context.pop();
              },
            ),
          ] else
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
        Icon(icon, size: 20, color: valueColor ?? AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: valueColor),
          ),
        ),
      ],
    );
  }
}
