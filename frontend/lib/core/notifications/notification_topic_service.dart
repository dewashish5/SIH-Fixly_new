import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationTopicService {
  NotificationTopicService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> subscribeForRole(String role) async {
    await _messaging.subscribeToTopic('fixly_all');
    await _messaging.subscribeToTopic(
      role == 'worker' ? 'fixly_workers' : 'fixly_customers',
    );
  }

  Future<void> unsubscribeForRole(String role) async {
    await _messaging.unsubscribeFromTopic('fixly_all');
    await _messaging.unsubscribeFromTopic(
      role == 'worker' ? 'fixly_workers' : 'fixly_customers',
    );
  }
}
