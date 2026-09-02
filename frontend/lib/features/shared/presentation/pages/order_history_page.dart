import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../bookings/data/bookings_api_repository.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

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
      showBack: false,
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
              return ListView(
                physics: appRefreshScrollPhysics,
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                  Center(child: Text(context.l10n.noOrdersYet)),
                ],
              );
            }

            return ListView.separated(
              physics: appRefreshScrollPhysics,
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.serviceTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusBadge(
                            label: _statusLabel(order.status),
                            color: _statusColor(order.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (order.address != null) Text(order.address!),
                      if (order.scheduledAt != null)
                        Text(dateFormat.format(order.scheduledAt!)),
                      const SizedBox(height: 8),
                      Text(
                        '₹${order.estimatedPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                );
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
