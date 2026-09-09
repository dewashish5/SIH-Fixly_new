import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/worker_realtime_service.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../ai/presentation/widgets/hey_flexi_voice_sheet.dart';
import '../cubit/worker_dashboard_cubit.dart';
import '../widgets/worker_sos_sheet.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkerDashboardCubit>().load();
  }

  Future<void> _handleAcceptJob(WorkerJob job) async {
    final cubit = context.read<WorkerDashboardCubit>();
    final success = await cubit.acceptJob(job.id);
    if (!mounted) return;

    if (success) {
      ToastUtils.showSuccess(
        context: context,
        message: '🎉 Job Accepted! Customer has been notified.',
      );
      context.push(RouteNames.workerActiveJob);
    } else {
      ToastUtils.showError(
        context: context,
        message: cubit.state.error ?? 'Failed to accept job. Please try again.',
      );
    }
  }

  Future<void> _handleDeclineJob(WorkerJob job) async {
    final cubit = context.read<WorkerDashboardCubit>();
    final success = await cubit.declineJob(job.id);
    if (!mounted) return;

    if (success) {
      ToastUtils.showToast(
        context: context,
        message: 'Job passed. We will send you other requests.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WorkerDashboardCubit, WorkerDashboardState>(
      builder: (context, state) {
        final workerName = state.workerName.isEmpty ? l10n.guestUser : state.workerName;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context, workerName, isDark),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'hey_flexi_worker_fab',
            onPressed: () => HeyFlexiVoiceSheet.show(context),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.mic_rounded),
            label: const Text(
              'Hey Flexi AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          body: AppRefreshIndicator(
            onRefresh: () => context.read<WorkerDashboardCubit>().load(),
            child: state.status == WorkerDashboardStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    physics: appRefreshScrollPhysics,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      // 1. Availability Status Hero Card
                      _buildAvailabilityHero(context, state, isDark),
                      const SizedBox(height: 16),

                      // 2. Incoming Job Requests (Direct Accept & Decline)
                      if (state.incomingJobs.isNotEmpty) ...[
                        _buildIncomingJobsSection(context, state, isDark),
                        const SizedBox(height: 16),
                      ],

                      // 3. Active Ongoing Job (If any)
                      if (state.activeJob != null) ...[
                        _buildActiveJobCard(context, state.activeJob!, isDark),
                        const SizedBox(height: 16),
                      ],

                      // 4. Performance & Earnings Metrics (2x2 Grid)
                      _buildStatsGrid(context, state, isDark),
                      const SizedBox(height: 20),

                      // 5. Worker Tools & Workspace Shortcuts
                      _buildToolsSection(context, isDark),
                    ],
                  ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String workerName, bool isDark) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi, $workerName 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 3),
                    Text(
                      'Cooperative Partner',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Live Socket Status Indicator
        StreamBuilder<bool>(
          stream: WorkerRealtimeService.instance.connectionStream,
          initialData: WorkerRealtimeService.instance.isConnected,
          builder: (context, snapshot) {
            final isLive = snapshot.data ?? false;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isLive
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLive ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLive ? 'LIVE' : 'IDLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLive ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 4),

        // Worker SOS Action (Dedicated worker safety modal)
        IconButton(
          tooltip: 'Worker Emergency SOS',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          onPressed: () => WorkerSosSheet.show(context),
        ),

        // Notifications
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push(RouteNames.sharedNotifications),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildAvailabilityHero(BuildContext context, WorkerDashboardState state, bool isDark) {
    final isOnline = state.isAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF064E3B), const Color(0xFF047857)]
              : isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                  : [const Color(0xFF334155), const Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.radar_rounded : Icons.pause_circle_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOnline ? 'ONLINE & ACTIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? const Color(0xFF34D399) : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isOnline
                      ? 'Receiving instant booking alerts nearby'
                      : 'Toggle on to receive customer job requests',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: isOnline,
              activeThumbColor: const Color(0xFF34D399),
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              onChanged: (_) => context.read<WorkerDashboardCubit>().toggleAvailability(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingJobsSection(BuildContext context, WorkerDashboardState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'NEW REQUESTS (${state.incomingJobs.length})',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.workerJobs),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Row(
                children: [
                  Text('All Jobs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final job in state.incomingJobs.take(2)) ...[
          _buildJobRequestCard(context, job, state.acceptingJobId == job.id, isDark),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildJobRequestCard(BuildContext context, WorkerJob job, bool isAccepting, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer: ${job.customerName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '₹${job.pay.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.address.isNotEmpty ? job.address : 'Near your service zone',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${job.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (job.problemDescription != null && job.problemDescription!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.problemDescription!,
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton(
                onPressed: isAccepting ? null : () => _handleDeclineJob(job),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAccepting ? null : () => _handleAcceptJob(job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isAccepting ? 'Accepting...' : 'Accept Job Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(BuildContext context, WorkerJob activeJob, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sync_rounded, color: Color(0xFF3B82F6), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE ONGOING JOB',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '₹${activeJob.pay.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeJob.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            'Customer: ${activeJob.customerName}',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activeJob.address,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (activeJob.customerPhone != null && activeJob.customerPhone!.isNotEmpty) ...[
                IconButton.filledTonal(
                  onPressed: () => launchUrl(Uri.parse('tel:${activeJob.customerPhone}')),
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB)),
                  tooltip: 'Call Customer',
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(RouteNames.workerActiveJob),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text(
                    'Open Task & Navigate',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WorkerDashboardState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance & Earnings',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Today Earnings',
                value: '₹${state.todayEarnings.toStringAsFixed(0)}',
                subtitle: 'Payout on schedule',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => context.push(RouteNames.workerEarnings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Jobs Done',
                value: '${state.completedJobs}',
                subtitle: 'All-time fulfilled',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF2563EB),
                isDark: isDark,
                onTap: () => context.push(RouteNames.workerJobs),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Reliability',
                value: '${state.reliabilityScore}%',
                subtitle: 'Top Tier Rating',
                icon: Icons.verified_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => context.push(RouteNames.workerReliability),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Welfare Fund',
                value: '₹${state.welfareFund.toStringAsFixed(0)}',
                subtitle: 'e-Shram & Insurance',
                icon: Icons.security_rounded,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => context.push(RouteNames.workerWelfare),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Worker Workspace & Tools',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _ToolCard(
              title: 'Job Feed',
              subtitle: 'Nearby broadcast requests',
              icon: Icons.work_outline_rounded,
              color: const Color(0xFF0284C7),
              isDark: isDark,
              onTap: () => context.push(RouteNames.workerJobs),
            ),
            _ToolCard(
              title: 'My Wallet',
              subtitle: 'Bank & UPI payouts',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF059669),
              isDark: isDark,
              onTap: () => context.push(RouteNames.workerWallet),
            ),
            _ToolCard(
              title: 'Welfare & Benefits',
              subtitle: 'e-Shram, medical, schemes',
              icon: Icons.shield_outlined,
              color: const Color(0xFF7C3AED),
              isDark: isDark,
              onTap: () => context.push(RouteNames.workerWelfare),
            ),
            _ToolCard(
              title: 'Earnings Analytics',
              subtitle: 'Weekly & monthly charts',
              icon: Icons.insights_rounded,
              color: const Color(0xFFD97706),
              isDark: isDark,
              onTap: () => context.push(RouteNames.workerEarnings),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
