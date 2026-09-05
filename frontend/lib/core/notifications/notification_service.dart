import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase/firebase_bootstrap.dart';
import 'notification_channels.dart';
import 'notification_token_service.dart';
import 'notification_topic_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS-rendered notification payloads need no additional background work.
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _tokenService = NotificationTokenService();
  final _topicService = NotificationTopicService();
  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized || !FirebaseBootstrap.isFirebaseReady) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationChannels.booking,
            'Booking updates',
            description: 'Updates about Fixly bookings and jobs.',
            importance: Importance.high,
          ),
        );
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _register(token, locale: 'en');
    });
    _initialized = true;
  }

  Future<void> onAuthenticated({
    required String role,
    required String locale,
  }) async {
    await initialize();
    if (!_initialized) return;
    try {
      await _topicService.subscribeForRole(role);
    } catch (error) {
      debugPrint('FCM topic subscription skipped: $error');
    }
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    _currentToken = token;
    await _register(token, locale: locale);
  }

  Future<void> onSignedOut() async {
    try {
      await _topicService.unsubscribeForRole('customer');
      await _topicService.unsubscribeForRole('worker');
    } catch (error) {
      debugPrint('FCM topic cleanup skipped: $error');
    }
    final token = _currentToken;
    if (token == null) return;
    try {
      await _tokenService.remove(token);
    } catch (error) {
      debugPrint('FCM token cleanup skipped: $error');
    } finally {
      _currentToken = null;
    }
  }

  Future<void> _register(String token, {required String locale}) async {
    try {
      await _tokenService.register(token: token, locale: locale);
    } catch (error) {
      debugPrint('FCM token registration skipped: $error');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.booking,
          'Booking updates',
          channelDescription: 'Updates about Fixly bookings and jobs.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> dispose() async => _tokenSubscription?.cancel();
}
