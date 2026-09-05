import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/active_job_cubit.dart';

class WorkerActiveJobPage extends StatefulWidget {
  const WorkerActiveJobPage({super.key});

  @override
  State<WorkerActiveJobPage> createState() => _WorkerActiveJobPageState();
}

class _WorkerActiveJobPageState extends State<WorkerActiveJobPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActiveJobCubit>().load();
  }

  void _showCompleteDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Job'),
        content: const Text('Did you use any extra parts for this job?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ActiveJobCubit>().completeJob();
              context.push('${RouteNames.workerRating}?bookingId=$bookingId');
            },
            child: const Text('No, Complete Directly'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('${RouteNames.workerAddParts}?bookingId=$bookingId');
            },
            child: const Text('Yes, Add Parts'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveJobCubit, ActiveJobState>(
      listener: (context, state) {
        if (state.status == ActiveJobStatus.reviewSubmitted || state.status == ActiveJobStatus.completed) {
          if (state.status == ActiveJobStatus.reviewSubmitted) {
            context.go(RouteNames.workerDashboard);
          } else {
            // When completed, go to rating if we haven't already.
            if (state.job != null) {
              context.push('${RouteNames.workerRating}?bookingId=${state.job!.id}&customerId=${state.job!.customerLat}'); // passing lat as mock for now, actual is needed if avail
            }
          }
        }
      },
      builder: (context, state) {
        if (state.status == ActiveJobStatus.loading && state.job == null) {
          return const AppScaffold(
            title: 'Active Job',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final job = state.job;
        if (job == null) {
          return const AppScaffold(
            title: 'Active Job',
            body: Center(child: Text('No active job')),
          );
        }

        final rawStatus = job.rawStatus ?? '';

        return AppScaffold(
          title: 'Active Job',
          padding: EdgeInsets.zero,
          body: Column(
            children: [
              _buildStatusBanner(rawStatus),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () => context.read<ActiveJobCubit>().load(),
                  child: ListView(
                    physics: appRefreshScrollPhysics,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildServiceCard(job, context),
                    const SizedBox(height: 16),
                    _buildCustomerCard(job, context),
                    if (job.problemDescription != null && job.problemDescription!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildProblemDescriptionCard(job, context),
                    ],
                    if (job.problemPhotos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildProblemPhotos(job),
                    ],
                    const SizedBox(height: 16),
                    _buildInvoiceCard(job, context),
                    const SizedBox(height: 32),
                    _buildBottomAction(rawStatus, job, context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(String rawStatus) {
    Color bgColor = AppColors.primary100;
    Color textColor = AppColors.primary;
    String text = 'Worker Accepted — Head to customer';

    if (rawStatus == 'ARRIVED') {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      text = 'Arrived — Awaiting OTP verification';
    } else if (rawStatus == 'IN_PROGRESS') {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      text = 'Job In Progress';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: bgColor,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildServiceCard(dynamic job, BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.serviceImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  job.serviceImage!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 120, child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          Text(
            job.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (job.serviceCategory != null)
            Text(
              job.serviceCategory!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(dynamic job, BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: job.customerAvatar != null ? NetworkImage(job.customerAvatar!) : null,
                child: job.customerAvatar == null ? Text(job.customerName[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      job.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (job.customerPhone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(job.customerPhone!),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.primary),
                  onPressed: () => launchUrl(Uri.parse('tel:${job.customerPhone}')),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildProblemDescriptionCard(dynamic job, BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Problem Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(job.problemDescription ?? ''),
        ],
      ),
    );
  }

  Widget _buildProblemPhotos(dynamic job) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: job.problemPhotos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              job.problemPhotos[index],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(dynamic job, BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pricing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (job.baseServiceFee != null) ...[
            _buildPriceRow('Base fee', job.baseServiceFee!),
            const SizedBox(height: 8),
          ],
          if (job.extraPartsTotal != null && job.extraPartsTotal! > 0) ...[
            _buildPriceRow('Extra parts', job.extraPartsTotal!),
            const SizedBox(height: 8),
          ],
          if (job.platformFee != null) ...[
            _buildPriceRow('Platform fee', job.platformFee!),
            const SizedBox(height: 8),
          ],
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹${job.pay.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text('₹${amount.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildBottomAction(String rawStatus, dynamic job, BuildContext context) {
    if (rawStatus == 'APPROVED' || rawStatus == 'ACCEPTED') {
      return SwipeActionButton(
        label: 'Swipe to Navigate',
        onCompleted: () => context.push('${RouteNames.workerNavigation}?bookingId=${job.id}'),
      );
    } else if (rawStatus == 'ARRIVED') {
      return SwipeActionButton(
        label: 'Swipe to Enter OTP',
        onCompleted: () => context.push('${RouteNames.workerOtpEntry}?bookingId=${job.id}'),
      );
    } else if (rawStatus == 'IN_PROGRESS') {
      return Column(
        children: [
          Text(
            'Job started at ${job.jobStartedAt != null ? job.jobStartedAt!.toLocal().toString().split('.').first : 'Just now'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SwipeActionButton(
            label: 'Swipe to Complete Job',
            onCompleted: () => _showCompleteDialog(context, job.id),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}
