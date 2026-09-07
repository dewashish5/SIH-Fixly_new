/// API host. Override via `--dart-define=API_BASE_URL=...` or `dart_defines.json`.
/// Public Cloudflare tunnel — host must keep backend + cloudflared running.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8005',
  );
}

// import 'dart:io';

// /// API Configuration
// class ApiConfig {
//   ApiConfig._();

//   static const String _envUrl = String.fromEnvironment(
//     'API_BASE_URL',
//     defaultValue: '',
//   );

//   static String get baseUrl => _envUrl.isNotEmpty
//       ? _envUrl
//       : Platform.isAndroid
//       ? 'http://10.0.2.2:8005' // Android Emulator -> localhost
//       : Platform.isIOS
//       ? 'http://localhost:8005' // iOS Simulator -> localhost
//       : 'http://localhost:8005'; // Fallback (Web/macOS/Windows/Linux)
// }
