import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../cubit/job_feed_cubit.dart';

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
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      await BookingsApiRepository().accept(widget.jobId);
      await AppPreferences.instance.setActiveWorkerJobId(widget.jobId);
      if (!mounted) return;
      ToastUtils.showSuccess(
        context: context,
        message: '🎉 Booking accepted! Head to the customer location.',
      );
      context.go(RouteNames.workerActiveJob);
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ToastUtils.showError(context: context, message: e.toString());
    }
  }

  Future<void> _callCustomer(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatMediaUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$base$cleanPath';
  }

  void _previewImage(BuildContext context, String url) {
    final fullUrl = _formatMediaUrl(url);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                clipBehavior: Clip.none,
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'Unable to load photo',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMediaUrl(String url) async {
    final fullUrl = _formatMediaUrl(url);
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return AppScaffold(
        title: context.l10n.orderDetails,
        showBack: true,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;
    final fallback = _feedJob;
    if (booking == null && fallback == null) {
      return AppScaffold(
        title: context.l10n.orderDetails,
        showBack: true,
        body: Center(child: Text(_error ?? 'Booking not found')),
      );
    }

    final title = booking?.serviceTitle ?? fallback?.title ?? 'Service Booking';
    final customerName =
        booking?.customerName ?? fallback?.customerName ?? 'Customer';
    final customerPhone = booking?.customerPhone ?? fallback?.customerPhone;
    final address = booking?.address ?? fallback?.address ?? '';
    final amount = booking?.totalAmount ??
        booking?.totalPrice ??
        booking?.estimatedPrice ??
        fallback?.pay ??
        0;

    final isPending = booking?.status == BookingStatus.searching ||
        fallback?.status == JobStatus.incoming;

    final isActive = booking?.status == BookingStatus.accepted ||
        booking?.status == BookingStatus.arrived ||
        booking?.status == BookingStatus.inProgress ||
        fallback?.status == JobStatus.active;

    final isCompleted = booking?.status == BookingStatus.completed ||
        booking?.status == BookingStatus.paid ||
        fallback?.status == JobStatus.completed;

    final isSos = booking?.isSosBooking ?? fallback?.isSosBooking ?? false;
    final isScheduled =
        booking?.isScheduledBooking ?? fallback?.isScheduledBooking ?? false;
    final scheduledAt = booking?.scheduledAt ?? fallback?.scheduledAt;
    final timeSlot = booking?.timeSlot;

    final problemDesc =
        booking?.problemDescription ?? fallback?.problemDescription;
    final photos = booking?.problemPhotos.isNotEmpty == true
        ? booking!.problemPhotos
        : (fallback?.problemPhotos ?? const <String>[]);
    final videos = booking?.problemVideos.isNotEmpty == true
        ? booking!.problemVideos
        : (fallback?.problemVideos ?? const <String>[]);

    return AppScaffold(
      title: context.l10n.orderDetails,
      showBack: true,
      body: AppRefreshIndicator(
        onRefresh: _resolve,
        child: SingleChildScrollView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Acceptance Status Prompt Banner
              if (isPending)
                _buildStatusBanner(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Customer is waiting for acceptance',
                  subtitle:
                      'Accept this booking to get navigation and customer contact. You have to go once accepted.',
                  isDark: isDark,
                  isAlert: true,
                )
              else if (isActive)
                _buildStatusBanner(
                  icon: Icons.navigation_rounded,
                  title: 'Job Accepted • You are en route',
                  subtitle:
                      'Customer is expecting your arrival. Head over to the location.',
                  isDark: isDark,
                  isAlert: false,
                )
              else if (isCompleted)
                _buildStatusBanner(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Order Fulfilled & Settled',
                  subtitle: 'This service request has been completed.',
                  isDark: isDark,
                  isAlert: false,
                ),

              const SizedBox(height: 16),

              // 2. Job Type Badge & Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJobTypeBadge(
                          isSos: isSos,
                          isScheduled: isScheduled,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Guaranteed Payout',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 16),

              // 3. Customer & Location Information
              _buildSectionTitle('Customer & Location', isDark),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? Colors.white12
                              : const Color(0xFF0F172A).withValues(alpha: 0.1),
                          child: Text(
                            customerName.isNotEmpty
                                ? customerName.substring(0, 1).toUpperCase()
                                : 'C',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (customerPhone != null && customerPhone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  customerPhone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (customerPhone != null && customerPhone.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _callCustomer(customerPhone),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 14),
                            label: const Text(
                              'Call',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.isNotEmpty ? address : 'Address not specified',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isScheduled && scheduledAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Slot: ${DateFormat('EEE, MMM d, y • h:mm a').format(scheduledAt)}${timeSlot != null ? ' ($timeSlot)' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Customer Problem Description & Attached Photos/Videos
              _buildSectionTitle('Customer Request & Media', isDark),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Problem Description
                    Text(
                      'Issue Description',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      problemDesc != null && problemDesc.trim().isNotEmpty
                          ? problemDesc.trim()
                          : 'No written description provided by customer.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: problemDesc == null || problemDesc.trim().isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),

                    // Photos Gallery
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Attached Photos (${photos.length}) • Tap to zoom',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final photoUrl = photos[index];
                            final formattedUrl = _formatMediaUrl(photoUrl);

                            return InkWell(
                              onTap: () => _previewImage(context, photoUrl),
                              borderRadius: BorderRadius.circular(8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  color: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
                                  child: Image.network(
                                    formattedUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image_rounded, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Videos Attachments
                    if (videos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Attached Video Clip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...videos.map((vidUrl) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () => _openMediaUrl(vidUrl),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'View Customer Video Attachment',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.open_in_new_rounded, size: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],

                    if (photos.isEmpty && videos.isEmpty && (problemDesc == null || problemDesc.isEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'No photo or video attachments sent.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Payout Breakdown Section
              _buildSectionTitle('Payout Breakdown', isDark),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Base Service Fee',
                      booking?.baseServiceFee ?? fallback?.baseServiceFee ?? (amount * 0.85),
                      isDark,
                    ),
                    if (isSos) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Emergency Dispatch Fee',
                        booking?.urgentFee ?? 100.0,
                        isDark,
                      ),
                    ],
                    if ((booking?.extraPartsTotal ?? 0) > 0 || (fallback?.extraPartsTotal ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Approved Replacement Parts',
                        booking?.extraPartsTotal ?? fallback?.extraPartsTotal ?? 0,
                        isDark,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Worker Payout',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 6. Action Button Section (Smooth Swiping + Decline or Active Navigation)
              if (isPending) ...[
                SwipeActionButton(
                  label: 'Swipe to accept booking',
                  enabled: !_accepting,
                  onCompleted: _accept,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _accepting
                        ? null
                        : () async {
                            await context.read<JobFeedCubit>().declineJob(widget.jobId);
                            if (context.mounted) context.pop();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Decline Job',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else if (isActive) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(RouteNames.workerActiveJob),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Go to Active Job Console',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Back to Job Feed'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isAlert,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert
              ? (isDark ? Colors.white24 : const Color(0xFF94A3B8))
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypeBadge({
    required bool isSos,
    required bool isScheduled,
    required bool isDark,
  }) {
    if (isSos) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'EMERGENCY SOS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.red,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    if (isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 12),
            SizedBox(width: 4),
            Text(
              'SCHEDULED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: const Text(
        'STANDARD',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

