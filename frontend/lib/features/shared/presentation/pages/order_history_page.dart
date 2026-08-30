import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../core/constants/app_strings.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = MockRepository.instance.orderHistory;
    final dateFormat = DateFormat('d MMM yyyy');

    if (orders.isEmpty) {
      return AppScaffold(
        title: context.l10n.orderHistory,
        body: Center(child: Text(context.l10n.noOrdersYet)),
      );
    }

    return AppScaffold(
      title: context.l10n.orderHistory,
      body: ListView.separated(
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
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
}
