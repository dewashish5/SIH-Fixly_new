part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<NotificationItem> items;
  final String? errorMessage;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItem>? items,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
