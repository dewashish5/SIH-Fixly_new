import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';
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
  Booking? _booking;
  WorkerJob? _feedJob;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final booking = await BookingsApiRepository().getById(widget.jobId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedJob = context.read<JobFeedCubit>().jobById(widget.jobId);
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await BookingsApiRepository().accept(widget.jobId);
      if (!mounted) return;
      context.go(RouteNames.workerActiveJob);
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
    final booking = _booking;
    final fallback = _feedJob;
    if (booking == null && fallback == null) {
      return AppScaffold(
        title: context.l10n.orderDetails,
        body: Center(child: Text(_error ?? 'Booking not found')),
      );
    }

    final title = booking?.serviceTitle ?? fallback!.title;
    final customerName =
        booking?.customerName ?? fallback?.customerName ?? 'Customer';
    final address = booking?.address ?? fallback?.address ?? '';
    final amount = booking?.estimatedPrice ?? fallback?.pay ?? 0;
    final isPending =
        booking?.status == BookingStatus.searching ||
        fallback?.status == JobStatus.incoming;

    return AppScaffold(
      title: context.l10n.orderDetails,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              StatusBadge(
                label: _statusLabel(booking?.status, fallback?.status),
                color: isPending ? AppColors.warning : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(customerName, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(icon: Icons.location_on_outlined, text: address),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.currency_rupee,
                  text: '₹${amount.toStringAsFixed(0)} payout',
                  valueColor: AppColors.accent,
                ),
                if (booking?.problemDescription?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.description_outlined,
                    text: booking!.problemDescription!,
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          if (isPending) ...[
            SwipeActionButton(
              label: 'Swipe to accept booking',
              enabled: !_accepting,
              onCompleted: _accept,
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Decline',
              onPressed: _accepting
                  ? null
                  : () async {
                      await context.read<JobFeedCubit>().declineJob(
                        widget.jobId,
                      );
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

String _statusLabel(BookingStatus? status, JobStatus? fallback) {
  if (status == BookingStatus.searching || fallback == JobStatus.incoming) {
    return 'Pending approval';
  }
  if (status == BookingStatus.completed || fallback == JobStatus.completed) {
    return 'Completed';
  }
  return 'Active';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text, this.valueColor});

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
          child: Text(text, style: TextStyle(color: valueColor)),
        ),
      ],
    );
  }
}
