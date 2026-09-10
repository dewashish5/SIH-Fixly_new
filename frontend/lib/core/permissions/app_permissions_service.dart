import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../location/location_service.dart';
import '../notifications/notification_service.dart';

/// Single launch-time permission gate for customer + worker.
///
/// Splash asks every runtime permission the app needs via
/// [permission_handler], then hydrates GPS / FCM. Later screens should not
/// re-prompt unless the user previously denied.
class AppPermissionsService {
  AppPermissionsService._();
  static final AppPermissionsService instance = AppPermissionsService._();

  bool _askedThisSession = false;

  /// Permissions required for both customer and worker flows.
  List<Permission> get requiredPermissions {
    final list = <Permission>[
      Permission.locationWhenInUse,
      Permission.notification,
      Permission.microphone,
      Permission.camera,
      Permission.photos,
      Permission.speech,
    ];
    // WebRTC / call audio routing on Android 12+.
    if (!kIsWeb && Platform.isAndroid) {
      list.add(Permission.bluetoothConnect);
    }
    return list;
  }

  /// Call once after splash animation — before login / home navigation.
  Future<void> requestAllAfterSplash(BuildContext context) async {
    if (_askedThisSession) return;
    _askedThisSession = true;

    try {
      await requiredPermissions.request();
    } catch (e) {
      debugPrint('AppPermissionsService: batch request failed: $e');
      // Fall back one-by-one so a single platform quirk does not skip the rest.
      for (final permission in requiredPermissions) {
        try {
          await permission.request();
        } catch (err) {
          debugPrint('AppPermissionsService: $permission failed: $err');
        }
      }
    }

    if (!context.mounted) return;

    // GPS services dialog + first fix (permission already requested above).
    try {
      await LocationService.instance.ensureOnAppOpen(context);
    } catch (e) {
      debugPrint('AppPermissionsService: location hydrate failed: $e');
    }

    // FCM / APNs registration (notification OS prompt already handled above).
    try {
      await NotificationService.instance.requestPermissionsAndSync();
    } catch (e) {
      debugPrint('AppPermissionsService: notification sync failed: $e');
    }
  }
}
