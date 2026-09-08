// /// API host. Override via `--dart-define=API_BASE_URL=...` or `dart_defines.json`.
// /// Public Cloudflare tunnel — host must keep backend + cloudflared running.
// class ApiConfig {
//   ApiConfig._();

//   static const String baseUrl = String.fromEnvironment(
//     'API_BASE_URL',
//     defaultValue: 'http://localhost:8005',
//   );
// }

import 'dart:io';

/// API Configuration
class ApiConfig {
  ApiConfig._();

  static const String _envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl => _envUrl.isNotEmpty
      ? _envUrl
      : Platform.isAndroid
      ? 'http://192.168.1.5:8000' // Android physical device -> local IP
      : Platform.isIOS
      ? 'http://192.168.1.5:8000' // iOS physical device -> local IP
      : 'http://192.168.1.5:8000'; // Fallback (Web/macOS/Windows/Linux)
}
