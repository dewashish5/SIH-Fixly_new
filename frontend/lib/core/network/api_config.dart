import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;

/// API host configuration with dynamic candidate failover.
class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8005',
  );

  static String? _overrideUrl;
  static final ValueNotifier<String> urlNotifier = ValueNotifier<String>(_defaultUrl);

  static void setBaseUrl(String url) {
    if (_overrideUrl != url) {
      _overrideUrl = url;
      urlNotifier.value = url;
    }
  }

  static String get baseUrl {
    if (_overrideUrl != null) {
      return _overrideUrl!;
    }
    if (const bool.hasEnvironment('API_BASE_URL')) {
      return _defaultUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8005';
    }
    if (Platform.isAndroid) {
      // Prioritize localhost (works with adb reverse for both physical device and emulator)
      return 'http://localhost:8005';
    }
    return 'http://localhost:8005'; // iOS simulator or desktop
  }

  static List<String> get candidateUrls {
    final urls = <String>[];
    urls.add(baseUrl);
    if (!urls.contains('http://localhost:8005')) urls.add('http://localhost:8005');
    if (!urls.contains('http://127.0.0.1:8005')) urls.add('http://127.0.0.1:8005');
    if (!urls.contains('http://192.168.1.197:8005')) {
      urls.add('http://192.168.1.197:8005');
    }
    if (Platform.isAndroid && !urls.contains('http://10.0.2.2:8005')) {
      urls.add('http://10.0.2.2:8005');
    }
    return urls;
  }
}
