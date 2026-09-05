import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late Future<Booking> _bookingFuture;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _loadBooking();
  }

  Future<Booking> _loadBooking() =>
      BookingsApiRepository().getById(widget.bookingId);

  void _retry() {
    setState(() {
      _bookingFuture = _loadBooking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Booking details',
      body: FutureBuilder<Booking>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorState(onRetry: _retry);
          }
          return _BookingDetails(booking: snapshot.data!);
        },
      ),
    );
  }
}

class _BookingDetails extends StatelessWidget {
  const _BookingDetails({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(booking.status);
    final scheduled = booking.scheduledAt;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (booking.serviceImage != null && booking.serviceImage!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              booking.serviceImage!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        if (booking.serviceImage != null && booking.serviceImage!.isNotEmpty)
          const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                booking.serviceTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _StatusChip(
              label: _statusLabel(booking.status),
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          booking.displayId == null
              ? 'Booking #${booking.id}'
              : '${booking.displayId}  •  ${booking.id}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 20),
        if (booking.serviceCategory != null || booking.estimatedTime != null)
          AppCard(
            child: Row(
              children: [
                if (booking.serviceCategory != null)
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: booking.serviceCategory!,
                    ),
                  ),
                if (booking.estimatedTime != null)
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.timelapse_outlined,
                      label: 'Estimated time',
                      value: booking.estimatedTime!,
                    ),
                  ),
              ],
            ),
          ),
        if (booking.serviceCategory != null || booking.estimatedTime != null)
          const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (booking.workerName != null && booking.workerName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Professional',
                  value: booking.workerName!,
                ),
              if (booking.address != null && booking.address!.isNotEmpty) ...[
                if (booking.workerName != null &&
                    booking.workerName!.isNotEmpty)
                  const Divider(height: 24),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Service address',
                  value: booking.address!,
                ),
              ],
              if (scheduled != null) ...[
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Scheduled for',
                  value: DateFormat('d MMM yyyy, h:mm a').format(scheduled),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (booking.paymentStatus != null ||
                  booking.paymentMethod != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    [
                      if (booking.paymentStatus != null)
                        'Status: ${_paymentLabel(booking.paymentStatus!)}',
                      if (booking.paymentMethod != null)
                        'Method: ${booking.paymentMethod}',
                    ].join('  •  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              _ChargeRow(label: 'Service fee', amount: booking.baseServiceFee),
              _ChargeRow(label: 'Platform fee', amount: booking.platformFee),
              _ChargeRow(label: 'Extra parts', amount: booking.extraPartsTotal),
              const Divider(height: 24),
              _ChargeRow(
                label: 'Total amount',
                amount: booking.estimatedPrice,
                emphasize: true,
              ),
            ],
          ),
        ),
        if (booking.problemDescription != null &&
            booking.problemDescription!.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: _InfoRow(
              icon: Icons.description_outlined,
              label: 'Issue reported',
              value: booking.problemDescription!,
            ),
          ),
        ],
        if (booking.problemPhotos.isNotEmpty ||
            booking.problemVideos.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploaded evidence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        booking.problemPhotos.length +
                        booking.problemVideos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isPhoto = index < booking.problemPhotos.length;
                      final url = isPhoto
                          ? booking.problemPhotos[index]
                          : booking.problemVideos[index -
                                booking.problemPhotos.length];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              url,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                            if (!isPhoto)
                              const Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 30,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        if (booking.whatsIncluded.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service includes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in booking.whatsIncluded)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 17,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        AppCard(child: _BookingProgress(booking: booking)),
        if (booking.arrivalOtp != null &&
            (booking.status == BookingStatus.accepted ||
                booking.status == BookingStatus.inProgress)) ...[
          const SizedBox(height: 16),
          AppCard(
            child: _InfoRow(
              icon: Icons.lock_outline,
              label: 'Arrival OTP',
              value: booking.arrivalOtp!,
            ),
          ),
        ],
        if (booking.addOns.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Added parts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final part in booking.addOns)
                  _ChargeRow(
                    label: '${part.title} x${part.quantity}',
                    amount: part.price * part.quantity,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _StatusActions(booking: booking),
      ],
    );
  }
}

class _BookingProgress extends StatelessWidget {
  const _BookingProgress({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Booking placed', booking.createdAt != null),
      (
        'Professional accepted',
        booking.status != BookingStatus.searching &&
            booking.status != BookingStatus.draft,
      ),
      (
        'Work started',
        booking.jobStartedAt != null ||
            booking.status == BookingStatus.inProgress ||
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.paid,
      ),
      (
        'Work completed',
        booking.jobCompletedAt != null ||
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.paid,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking progress',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  step.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 19,
                  color: step.$2
                      ? AppColors.success
                      : Theme.of(context).hintColor,
                ),
                const SizedBox(width: 9),
                Text(
                  step.$1,
                  style: TextStyle(
                    color: step.$2 ? null : Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double? amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    if (amount == null && !emphasize) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '₹${(amount ?? 0).toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: emphasize ? AppColors.primary : null,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 44),
          const SizedBox(height: 12),
          const Text('Unable to load booking details'),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}

String _statusLabel(BookingStatus status) {
  switch (status) {
    case BookingStatus.completed:
      return 'Completed';
    case BookingStatus.paid:
      return 'Paid';
    case BookingStatus.inProgress:
      return 'In progress';
    case BookingStatus.arrived:
      return 'Arrived';
    case BookingStatus.accepted:
      return 'Accepted';
    case BookingStatus.searching:
      return 'Searching';
    case BookingStatus.draft:
      return 'Pending';
  }
}

Color _statusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.completed:
    case BookingStatus.paid:
      return AppColors.success;
    case BookingStatus.inProgress:
    case BookingStatus.accepted:
    case BookingStatus.arrived:
      return AppColors.primary;
    default:
      return AppColors.outline;
  }
}

String _paymentLabel(String status) {
  return status
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    switch (booking.status) {
      case BookingStatus.searching:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SecondaryButton(
              label: 'Cancel Booking',
              onPressed: () async {
                await BookingsApiRepository().cancel(booking.id);
                if (context.mounted) context.pop();
              },
            ),
          ],
        );
      case BookingStatus.accepted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: 'Track Worker Live',
              onPressed: () => context.push('/customer/tracking?bookingId=${booking.id}'),
            ),
          ],
        );
      case BookingStatus.arrived:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB4C5FF)),
              ),
              child: const Text(
                'Worker has arrived! Share OTP to start work.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      case BookingStatus.inProgress:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_circle_outlined, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Work is in progress...'),
                ],
              ),
            ),
          ],
        );
      case BookingStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: 'Pay Now',
              onPressed: () {
                context.push(RouteNames.customerInvoice.replaceFirst(':id', booking.id));
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
