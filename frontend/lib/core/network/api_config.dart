import 'package:flutter/foundation.dart' show ValueNotifier;

/// API configuration — change [baseUrl] to point to your backend.
class ApiConfig {
  ApiConfig._();

  // ─── ✏️  CHANGE THIS to your backend URL ───────────────────────────────────
  //
  //  Android emulator (AVD):         http://10.0.2.2:8005
  //  iOS Simulator:                  http://localhost:8005
  //  Physical device (your WiFi):    http://192.168.1.88:8005  ← your LAN IP
  //  Tunnel / production:            https://your-tunnel-url.com
  //
  static const String baseUrl =
      'http://fexily-lb-380632449.ap-south-1.elb.amazonaws.com';
  // ───────────────────────────────────────────────────────────────────────────

  /// Notifier in case any widget needs to react to URL changes at runtime.
  static final ValueNotifier<String> urlNotifier = ValueNotifier<String>(
    baseUrl,
  );
}
