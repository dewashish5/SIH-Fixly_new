part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
  });

  final NotificationsStatus status;
  final List<NotificationItem> items;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItem>? items,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [status, items];
}
