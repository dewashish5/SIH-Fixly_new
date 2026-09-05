import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPermissionService {
  NotificationPermissionService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<AuthorizationStatus> status() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<bool> isGranted() async {
    final current = await status();
    return current == AuthorizationStatus.authorized ||
        current == AuthorizationStatus.provisional;
  }

  Future<AuthorizationStatus> request() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus;
  }
}
