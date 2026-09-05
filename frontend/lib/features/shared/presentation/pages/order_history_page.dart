import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../../app/router/route_names.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<Booking>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Booking>> _fetchOrders() => BookingsApiRepository().history();

  Future<void> _onRefresh() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return AppScaffold(
      title: context.l10n.orderHistory,
      showBack: widget.showBack,
      body: AppRefreshIndicator(
        onRefresh: _onRefresh,
        child: FutureBuilder<List<Booking>>(
          future: _ordersFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return ListView(
                physics: appRefreshScrollPhysics,
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            final orders = snap.data ?? const [];
            if (orders.isEmpty) {
              final scheme = Theme.of(context).colorScheme;
              return ListView(
                physics: appRefreshScrollPhysics,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 40,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      context.l10n.noOrdersYet,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Your completed and ongoing bookings will show up here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final scheme = Theme.of(context).colorScheme;
                final statusColor = _statusColor(order.status);

                return Material(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        context.push(RouteNames.bookingDetailPath(order.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.handyman_outlined,
                                  size: 22,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.serviceTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (order.serviceCategory != null ||
                                        order.displayId != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if (order.serviceCategory != null)
                                            order.serviceCategory!,
                                          if (order.displayId != null)
                                            order.displayId!,
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                      ),
                                    ],
                                    if (order.scheduledAt != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(order.scheduledAt!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.fromBorderSide(
                                    BorderSide(
                                      color: statusColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _statusLabel(order.status),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (order.address != null &&
                              order.address!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.address!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (order.workerName != null &&
                              order.workerName!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Professional: ${order.workerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total amount',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  if (order.paymentStatus != null)
                                    Text(
                                      'Payment: ${_paymentLabel(order.paymentStatus!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context).hintColor,
                                          ),
                                    ),
                                ],
                              ),
                              Text(
                                '₹${order.estimatedPrice.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).appListEnter(context, index: index, id: order.id);
              },
            );
          },
        ),
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
    case BookingStatus.accepted:
      return 'Accepted';
    case BookingStatus.searching:
      return 'Searching';
    case BookingStatus.draft:
      return 'Draft';
  }
}

Color _statusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.completed:
    case BookingStatus.paid:
      return AppColors.success;
    case BookingStatus.inProgress:
    case BookingStatus.accepted:
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
