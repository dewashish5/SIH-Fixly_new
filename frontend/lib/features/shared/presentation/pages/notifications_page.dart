import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/notification_payload.dart';
import '../../../../core/notifications/notification_router.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/notifications_cubit.dart';
import '../../../../core/constants/app_strings.dart';

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
    final timeFormat = DateFormat('h:mm a');
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
            child: _buildBody(context, state, timeFormat, scheme),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    DateFormat timeFormat,
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
            color: scheme.error,
            child: Icon(Icons.delete_outline, color: scheme.onError),
          ),
          onDismissed: (_) =>
              context.read<NotificationsCubit>().delete(item.id),
          child: AppCard(
            onTap: () async {
              await context.read<NotificationsCubit>().markRead(item.id);
              if (!context.mounted) return;
              NotificationRouter.instance.handle(
                NotificationPayload(
                  eventType: item.eventType,
                  notificationId: item.id,
                  entityType: item.entityType,
                  entityId: item.entityId,
                  bookingId: item.bookingId,
                  action: item.action,
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!item.read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: item.read
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.body),
                      const SizedBox(height: 4),
                      Text(
                        timeFormat.format(item.time.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).appListEnter(context, index: index, id: item.id),
        );
      },
    );
  }
}
