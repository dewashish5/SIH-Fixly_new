import 'package:flutter_test/flutter_test.dart';

import 'package:fixly/core/notifications/notification_payload.dart';

void main() {
  test('normalizes FCM data values and parses the notification contract', () {
    final payload = NotificationPayload.fromMap({
      'eventType': 'BOOKING_ACCEPTED',
      'notificationId': 42,
      'entityType': 'booking',
      'entityId': 'booking-1',
      'action': 'booking_details',
      'version': 1,
    });

    expect(payload.eventType, 'BOOKING_ACCEPTED');
    expect(payload.notificationId, '42');
    expect(payload.entityId, 'booking-1');
    expect(payload.version, '1');
  });
}
