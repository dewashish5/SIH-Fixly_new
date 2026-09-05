import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationTopicService {
  NotificationTopicService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  static const all = 'fixly_all';
  static const customers = 'fixly_customers';
  static const workers = 'fixly_workers';
  static const customersMarketing = 'fixly_customers_marketing';
  static const workersMarketing = 'fixly_workers_marketing';

  Future<void> subscribeForRole(
    String role, {
    bool marketingEnabled = false,
  }) async {
    await unsubscribeAll();
    await _messaging.subscribeToTopic(all);
    await _messaging.subscribeToTopic(
      role == 'worker' ? workers : customers,
    );
    if (marketingEnabled) {
      await setMarketing(role, true);
    }
  }

  Future<void> setMarketing(String role, bool enabled) async {
    final topic = role == 'worker' ? workersMarketing : customersMarketing;
    if (enabled) {
      await _messaging.subscribeToTopic(topic);
    } else {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  Future<void> unsubscribeAll() async {
    await _messaging.unsubscribeFromTopic(all);
    await _messaging.unsubscribeFromTopic(customers);
    await _messaging.unsubscribeFromTopic(workers);
    await _messaging.unsubscribeFromTopic(customersMarketing);
    await _messaging.unsubscribeFromTopic(workersMarketing);
  }

  Future<void> unsubscribeForRole(String role) => unsubscribeAll();
}
