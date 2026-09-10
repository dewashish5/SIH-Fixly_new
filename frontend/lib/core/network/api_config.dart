import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;

/// API host configuration with dynamic candidate failover.
class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://processing-oakland-loc-talks.trycloudflare.com',
  );

  static String? _overrideUrl;
  
  static final ValueNotifier<String> urlNotifier = ValueNotifier<String>(
    _defaultUrl,
  );

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
    return _defaultUrl;
  }

  static List<String> get candidateUrls {
    final urls = <String>[];
    // 1. Primary: Cloudflare tunnel URL
    if (_overrideUrl != null && !urls.contains(_overrideUrl)) {
      urls.add(_overrideUrl!);
    }
    if (!urls.contains(_defaultUrl)) {
      urls.add(_defaultUrl);
    }
    // 2. Secondary fallback local hosts
    if (!urls.contains('http://localhost:8005')) {
      urls.add('http://localhost:8005');
    }
    if (!urls.contains('http://127.0.0.1:8005')) {
      urls.add('http://127.0.0.1:8005');
    }
    if (!kIsWeb && Platform.isAndroid && !urls.contains('http://10.0.2.2:8005')) {
      urls.add('http://10.0.2.2:8005');
    }
    return urls;
  }
}
