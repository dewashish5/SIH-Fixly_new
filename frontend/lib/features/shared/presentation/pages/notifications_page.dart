import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/notification_payload.dart';
import '../../../../core/notifications/notification_router.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/notifications_cubit.dart';
import '../../../../core/constants/app_strings.dart';

import '../../../../shared/models/models.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return AppScaffold(
          title: context.l10n.notifications,
          showBack: true,
          actions: [
            TextButton(
              onPressed: state.items.isEmpty
                  ? null
                  : () => context.read<NotificationsCubit>().markAllRead(),
              child: const Text('Mark all read'),
            ),
          ],
          body: RefreshIndicator(
            onRefresh: () => context.read<NotificationsCubit>().load(),
            child: _buildBody(context, state, scheme),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    ColorScheme scheme,
  ) {
    if (state.status == NotificationsStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == NotificationsStatus.failure && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off_outlined, size: 40, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            state.errorMessage ?? 'Could not load notifications',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => context.read<NotificationsCubit>().load(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('No notifications yet', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = state.items[index];

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete_outline, color: scheme.onError),
          ),
          onDismissed: (_) =>
              context.read<NotificationsCubit>().delete(item.id),
          child: Container(
            decoration: BoxDecoration(
              color: item.read ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.read
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFCBD5E1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.read<NotificationsCubit>().markRead(item.id);
                  final isWorker = context.read<AppSessionCubit>().currentUser?.role == UserRole.worker;
                  final resolvedBookingId = (item.bookingId != null && item.bookingId!.isNotEmpty)
                      ? item.bookingId
                      : (item.entityType == 'booking' && item.entityId != null && item.entityId!.isNotEmpty)
                          ? item.entityId
                          : item.data['bookingId']?.toString();

                  NotificationRouter.instance.handle(
                    NotificationPayload(
                      eventType: item.eventType,
                      notificationId: item.id,
                      entityType: item.entityType,
                      entityId: item.entityId,
                      bookingId: resolvedBookingId,
                      action: item.action,
                    ),
                    isWorker: isWorker,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Icon(
                          _getNotificationIcon(item),
                          size: 24,
                          color: item.read
                              ? const Color(0xFF64748B)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: item.read
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!item.read)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatNotificationTime(item.time),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).appListEnter(context, index: index, id: item.id),
        );
      },
    );
  }
}

IconData _getNotificationIcon(NotificationItem item) {
  final event = (item.eventType ?? '').toUpperCase();
  final action = (item.action ?? '').toLowerCase();
  final title = item.title.toLowerCase();
  final body = item.body.toLowerCase();

  if (event.contains('PAYMENT') ||
      action == 'payment' ||
      title.contains('payment') ||
      body.contains('payment')) {
    return Icons.payments_outlined;
  }
  if (event.contains('WALLET') ||
      event.contains('PAYOUT') ||
      action == 'wallet') {
    return Icons.account_balance_wallet_outlined;
  }
  if (event.contains('PROMO') ||
      event.contains('COUPON') ||
      action == 'discount' ||
      title.contains('offer') ||
      title.contains('coupon') ||
      title.contains('discount')) {
    return Icons.local_offer_outlined;
  }
  if (event.contains('INVOICE') ||
      action == 'invoice' ||
      title.contains('invoice')) {
    return Icons.receipt_long_outlined;
  }
  if (event.contains('COMPLETE') ||
      title.contains('completed') ||
      body.contains('completed')) {
    return Icons.check_circle_outline_rounded;
  }
  if (event.contains('ARRIV') ||
      title.contains('arrived') ||
      body.contains('arrived')) {
    return Icons.location_on_outlined;
  }
  if (event.contains('ASSIGN') ||
      event.contains('ACCEPT') ||
      title.contains('accepted') ||
      title.contains('assigned')) {
    return Icons.handyman_outlined;
  }
  if (event.contains('START') ||
      title.contains('started') ||
      body.contains('started')) {
    return Icons.engineering_outlined;
  }
  if (event.contains('CANCEL') ||
      title.contains('cancelled') ||
      title.contains('rejected')) {
    return Icons.cancel_outlined;
  }

  return Icons.notifications_none_rounded;
}

String _formatNotificationTime(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 &&
      local.day == now.day &&
      local.month == now.month &&
      local.year == now.year) {
    return 'Today, ${DateFormat('h:mm a').format(local)}';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (local.day == yesterday.day &&
      local.month == yesterday.month &&
      local.year == yesterday.year) {
    return 'Yesterday, ${DateFormat('h:mm a').format(local)}';
  }
  return DateFormat('dd MMM, h:mm a').format(local);
}
