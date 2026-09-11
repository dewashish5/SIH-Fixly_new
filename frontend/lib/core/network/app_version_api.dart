import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../utils/app_package_info.dart';
import 'api_client.dart';
import 'api_enpoints.dart';

/// Result of `GET /api/version` (Redis-backed on server).
class AppVersionCheck {
  const AppVersionCheck({
    required this.isUpdateAvailable,
    required this.forceUpdate,
    required this.updateUrl,
    required this.updateTitle,
    required this.updateMessage,
    this.latestAppVersion = '',
    this.clientAppVersion = '',
  });

  final bool isUpdateAvailable;
  final bool forceUpdate;
  final String updateUrl;
  final String updateTitle;
  final String updateMessage;
  final String latestAppVersion;
  final String clientAppVersion;

  factory AppVersionCheck.fromJson(Map<String, dynamic> json) {
    return AppVersionCheck(
      isUpdateAvailable: json['isUpdateAvailable'] == true,
      forceUpdate: json['forceUpdate'] == true,
      updateUrl: json['updateUrl']?.toString() ?? '',
      updateTitle: json['updateTitle']?.toString() ?? 'Update Available',
      updateMessage: json['updateMessage']?.toString() ??
          'A new version of Fixly is available. Please update the app.',
      latestAppVersion: json['appVersion']?.toString() ?? '',
      clientAppVersion: json['clientAppVersion']?.toString() ??
          AppPackageInfo.version,
    );
  }
}

/// Splash-screen version gate against backend Redis/Mongo version config.
abstract final class AppVersionApi {
  static String get _platform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'all';
    }
  }

  /// Calls public version endpoint. Throws on hard network/API failure.
  static Future<AppVersionCheck> check({ApiClient? client}) async {
    await AppPackageInfo.ensureInitialized();
    final api = client ?? ApiServices.client;
    final res = await api.get(
      ApiEndpoints.version,
      query: {
        'version': AppConstants.apiVersion,
        'apiVersion': AppConstants.apiVersion,
        'appVersion': AppPackageInfo.version,
        'platform': _platform,
      },
      forceNetwork: true,
    );
    return AppVersionCheck.fromJson(res);
  }
}
