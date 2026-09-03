import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
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
          body: state.status == NotificationsStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : state.items.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.separated(
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return AppCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!item.read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6, right: 12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
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
                                      timeFormat.format(item.time),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).appListEnter(
                          context,
                          index: index,
                          id: item.id,
                        );
                      },
                    ),
        );
      },
    );
  }
}
