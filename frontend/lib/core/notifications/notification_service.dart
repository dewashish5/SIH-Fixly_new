import 'dart:async';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../firebase/firebase_bootstrap.dart';
import '../network/api_client.dart';
import '../preferences/app_preferences.dart';
import '../utils/app_package_info.dart';
import '../../services/webrtc_call_service.dart';
import '../../app/router/app_router.dart';
import 'notification_channels.dart';
import 'notification_payload.dart';
import 'notification_permission_service.dart';
import 'notification_router.dart';
import 'notification_token_service.dart';
import 'notification_topic_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  if (data['type'] == 'INCOMING_CALL') {
    final params = CallKitParams(
      id: data['callSessionId'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
      nameCaller: data['callerName'] ?? 'Fixly User',
      appName: 'Fixly',
      avatar: data['callerAvatar'],
      handle: data['serviceTitle'] ?? 'Audio Calling',
      type: 0, // 0 = Audio Call
      duration: 30000,
      extra: <String, dynamic>{
        'bookingId': data['bookingId'],
        'callerId': data['callerId'],
        'callerRole': data['callerRole'],
        'serviceTitle': data['serviceTitle'],
        'callerName': data['callerName'],
        'callerAvatar': data['callerAvatar'],
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0F172A',
        actionColor: '#10B981',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  } else if (data['type'] == 'CANCEL_CALL') {
    final callSessionId = data['callSessionId'];
    if (callSessionId != null) {
      await FlutterCallkitIncoming.endCall(callSessionId.toString());
    } else {
      await FlutterCallkitIncoming.endAllCalls();
    }
  }
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
        android: AndroidInitializationSettings('@drawable/app_icon'),
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

    // CallKit Native Action Listener (Accept, Decline, End)
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      if (event is CallEventActionCallAccept) {
        final extra = event.callKitParams.extra;
        final bookingId = extra?['bookingId']?.toString();
        if (bookingId != null) {
          await WebRTCCallService.instance.acceptCall(
            bookingId: bookingId,
            callerName: extra?['callerName']?.toString(),
            callerRole: extra?['callerRole']?.toString(),
            callerAvatar: extra?['callerAvatar']?.toString(),
            serviceTitleParam: extra?['serviceTitle']?.toString(),
          );
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            context.push('/call');
          }
        }
      } else if (event is CallEventActionCallDecline) {
        WebRTCCallService.instance.rejectCall(reason: 'DECLINED');
      } else if (event is CallEventActionCallEnded) {
        WebRTCCallService.instance.hangUp();
      }
    });

    _initialized = true;

    // Proactively sync device FCM token to backend on app cold-start
    unawaited(_syncToken(locale: AppPreferences.instance.locale));
  }

  Future<void> requestPermissionsAndSync() async {
    await initialize();
    if (!_initialized) return;
    try {
      await _permissions.request();
      await _syncToken(locale: AppPreferences.instance.locale);
    } catch (error) {
      debugPrint('FCM requestPermissionsAndSync skipped: $error');
    }
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

  Future<void> setMarketingEnabled(bool enabled, {String? role}) async {
    final activeRole =
        role ?? _role ?? await ApiServices.tokens.role ?? 'customer';
    if (!_initialized) {
      await initialize();
    }
    try {
      await _topicService.setMarketing(activeRole, enabled);
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
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await _register(token, locale: locale);
    } catch (error) {
      debugPrint('FCM token sync skipped (expected on iOS Simulator): $error');
    }
  }

  Future<void> _register(String token, {String? locale}) async {
    try {
      await _tokenService.register(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        appVersion: AppPackageInfo.version,
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
    final data = message.data;
    if (data['type'] == 'INCOMING_CALL') {
      await firebaseMessagingBackgroundHandler(message);
      return;
    } else if (data['type'] == 'CANCEL_CALL') {
      final callSessionId = data['callSessionId'];
      if (callSessionId != null) {
        await FlutterCallkitIncoming.endCall(callSessionId.toString());
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
      return;
    }

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
          // Small icon = left of banner (status + heads-up). Do NOT set largeIcon —
          // Android draws largeIcon on the RIGHT, which looked unprofessional.
          icon: '@drawable/app_icon',
          channelShowBadge: true,
          color: const Color(0xFF2563EB),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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
