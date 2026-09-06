import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

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
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Permission.notification.request();
      } catch (_) {}
    }
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus;
  }
}
