import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase/firebase_bootstrap.dart';
import '../preferences/app_preferences.dart';
import 'notification_channels.dart';
import 'notification_payload.dart';
import 'notification_permission_service.dart';
import 'notification_router.dart';
import 'notification_token_service.dart';
import 'notification_topic_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS renders notification+data payloads. Keep this handler empty to avoid
  // a second local notification for the same message.
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _tokenService = NotificationTokenService();
  final _topicService = NotificationTopicService();
  final _permissions = NotificationPermissionService();
  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;
  String? _currentToken;
  String? _role;
  VoidCallback? onInboxInvalidated;

  Future<void> initialize() async {
    if (_initialized || !FirebaseBootstrap.isFirebaseReady) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/fixly_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = NotificationPayload.fromMap(
          _decodePayload(response.payload),
        );
        NotificationRouter.instance.handle(payload);
      },
    );
    await _createAndroidChannels();
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationRouter.instance.handle(
        NotificationPayload.fromMap(message.data),
      );
    });
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _register(token);
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      NotificationRouter.instance.handle(
        NotificationPayload.fromMap(initial.data),
      );
    }
    _initialized = true;
  }

  Future<void> onAuthenticated({
    required String role,
    required String locale,
    bool marketingEnabled = false,
  }) async {
    await initialize();
    if (!_initialized) return;
    _role = role;
    NotificationRouter.instance.setAuthReady(true);
    try {
      await _topicService.subscribeForRole(
        role,
        marketingEnabled: marketingEnabled,
      );
    } catch (error) {
      debugPrint('FCM topic subscription skipped: $error');
    }
    if (!await _permissions.isGranted()) return;
    await _syncToken(locale: locale);
  }

  Future<AuthorizationStatus> enablePushFromSettings() async {
    await initialize();
    if (!_initialized) return AuthorizationStatus.denied;
    final status = await _permissions.request();
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      await _syncToken(locale: AppPreferences.instance.locale);
    }
    return status;
  }

  Future<void> setMarketingEnabled(bool enabled) async {
    final role = _role;
    if (role == null || !_initialized) return;
    try {
      await _topicService.setMarketing(role, enabled);
    } catch (error) {
      debugPrint('FCM marketing topic skipped: $error');
    }
  }

  Future<void> onSignedOut() async {
    NotificationRouter.instance.setAuthReady(false);
    try {
      await _topicService.unsubscribeAll();
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
      _role = null;
    }
  }

  Future<void> _syncToken({required String locale}) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    _currentToken = token;
    await _register(token, locale: locale);
  }

  Future<void> _register(String token, {String? locale}) async {
    try {
      await _tokenService.register(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        appVersion: '0.1.0',
        locale: locale ?? AppPreferences.instance.locale,
      );
    } catch (error) {
      debugPrint('FCM token registration skipped: $error');
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.booking,
        'Booking updates',
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.workerJobs,
        'Nearby jobs',
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.payment,
        'Payments',
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.safety,
        'Safety alerts',
        importance: Importance.max,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.general,
        'General',
        importance: Importance.defaultImportance,
      ),
    );
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final payload = NotificationPayload.fromMap(message.data);
    final channelId = NotificationChannels.forEvent(payload.eventType);
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: channelId == NotificationChannels.safety
              ? Importance.max
              : Importance.high,
          priority: channelId == NotificationChannels.safety
              ? Priority.max
              : Priority.high,
          icon: '@drawable/fixly_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
    onInboxInvalidated?.call();
  }

  Map<String, dynamic> _decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final map = <String, dynamic>{};
    for (final part in raw.split('&')) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      map[part.substring(0, index)] = Uri.decodeComponent(
        part.substring(index + 1),
      );
    }
    return map;
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map(
          (entry) =>
              '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
        )
        .join('&');
  }

  Future<void> dispose() async => _tokenSubscription?.cancel();
}
