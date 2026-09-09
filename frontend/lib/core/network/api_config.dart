import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API host configuration with dynamic candidate failover.
class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8005',
  );

  static String get baseUrl {
    if (const bool.hasEnvironment('API_BASE_URL')) {
      return _defaultUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8005';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8005'; // Android Emulator
    }
    return 'http://localhost:8005'; // iOS simulator or desktop
  }
}
