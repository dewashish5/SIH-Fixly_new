class NotificationPayload {
  const NotificationPayload({
    this.eventType,
    this.notificationId,
    this.entityType,
    this.entityId,
    this.bookingId,
    this.action,
    this.version = '1',
  });

  final String? eventType;
  final String? notificationId;
  final String? entityType;
  final String? entityId;
  final String? bookingId;
  final String? action;
  final String version;

  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    String? value(String key) {
      final raw = data[key];
      return raw?.toString();
    }

    return NotificationPayload(
      eventType: value('eventType'),
      notificationId: value('notificationId'),
      entityType: value('entityType'),
      entityId: value('entityId'),
      bookingId: value('bookingId'),
      action: value('action'),
      version: value('version') ?? '1',
    );
  }
}
