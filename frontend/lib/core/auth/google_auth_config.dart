import 'dart:convert';

/// Resolved OAuth / Firebase values for Google Sign-In.
class GoogleAuthConfig {
  const GoogleAuthConfig({
    this.webClientId,
    this.iosClientId,
    this.iosReversedClientId,
    this.projectId,
    this.messagingSenderId,
    this.storageBucket,
    this.androidApiKey,
    this.androidAppId,
    this.iosApiKey,
    this.iosAppId,
    this.iosBundleId,
  });

  final String? webClientId;
  final String? iosClientId;
  final String? iosReversedClientId;
  final String? projectId;
  final String? messagingSenderId;
  final String? storageBucket;
  final String? androidApiKey;
  final String? androidAppId;
  final String? iosApiKey;
  final String? iosAppId;
  final String? iosBundleId;

  bool get hasGoogleSignInIds {
    final web = webClientId?.trim();
    if (web == null || web.isEmpty || _isPlaceholder(web)) return false;
    return true;
  }

  bool get hasFirebaseAndroidConfig {
    final key = androidApiKey?.trim();
    final appId = androidAppId?.trim();
    if (key == null ||
        appId == null ||
        _isPlaceholder(key) ||
        _isPlaceholder(appId)) {
      return false;
    }
    return true;
  }

  bool get hasFirebaseIosConfig {
    final key = iosApiKey?.trim();
    final appId = iosAppId?.trim();
    if (key == null ||
        appId == null ||
        _isPlaceholder(key) ||
        _isPlaceholder(appId)) {
      return false;
    }
    return true;
  }

  static bool _isPlaceholder(String value) {
    return value.contains('REPLACE_ME') ||
        value.contains('123456789') ||
        value.contains('abcdef');
  }

  static GoogleAuthConfig merge(
    GoogleAuthConfig base,
    GoogleAuthConfig overlay,
  ) {
    return GoogleAuthConfig(
      webClientId: overlay.webClientId ?? base.webClientId,
      iosClientId: overlay.iosClientId ?? base.iosClientId,
      iosReversedClientId:
          overlay.iosReversedClientId ?? base.iosReversedClientId,
      projectId: overlay.projectId ?? base.projectId,
      messagingSenderId: overlay.messagingSenderId ?? base.messagingSenderId,
      storageBucket: overlay.storageBucket ?? base.storageBucket,
      androidApiKey: overlay.androidApiKey ?? base.androidApiKey,
      androidAppId: overlay.androidAppId ?? base.androidAppId,
      iosApiKey: overlay.iosApiKey ?? base.iosApiKey,
      iosAppId: overlay.iosAppId ?? base.iosAppId,
      iosBundleId: overlay.iosBundleId ?? base.iosBundleId,
    );
  }

  static GoogleAuthConfig fromFirebaseClientJson(Map<String, dynamic> json) {
    final googleSignIn = Map<String, dynamic>.from(
      (json['googleSignIn'] as Map?) ?? const {},
    );
    final android = Map<String, dynamic>.from(
      (json['android'] as Map?) ?? const {},
    );
    final ios = Map<String, dynamic>.from(
      (json['ios'] as Map?) ?? const {},
    );

    return GoogleAuthConfig(
      webClientId: googleSignIn['webClientId'] as String?,
      iosClientId: googleSignIn['iosClientId'] as String?,
      iosReversedClientId: googleSignIn['iosReversedClientId'] as String?,
      projectId: json['projectId'] as String?,
      messagingSenderId: json['messagingSenderId'] as String?,
      storageBucket: json['storageBucket'] as String?,
      androidApiKey: android['apiKey'] as String?,
      androidAppId: android['appId'] as String?,
      iosApiKey: ios['apiKey'] as String?,
      iosAppId: ios['appId'] as String?,
      iosBundleId: ios['iosBundleId'] as String?,
    );
  }

  static GoogleAuthConfig? fromGoogleServicesJson(Map<String, dynamic> json) {
    final projectInfo = Map<String, dynamic>.from(
      (json['project_info'] as Map?) ?? const {},
    );
    final clients = json['client'] as List?;
    if (clients == null || clients.isEmpty) return null;

    String? webClientId;
    String? androidApiKey;
    String? androidAppId;

    for (final entry in clients) {
      final client = Map<String, dynamic>.from(entry as Map);
      final info = Map<String, dynamic>.from(
        (client['client_info'] as Map?) ?? const {},
      );
      final package = info['android_client_info'] as Map?;
      if (package == null) continue;

      androidApiKey = ((client['api_key'] as List?)?.first as Map?)
          ?.cast<String, dynamic>()['current_key'] as String?;
      androidAppId = info['mobilesdk_app_id'] as String?;

      final oauthClients = client['oauth_client'] as List?;
      if (oauthClients == null) continue;
      for (final oauthEntry in oauthClients) {
        final oauth = Map<String, dynamic>.from(oauthEntry as Map);
        if (oauth['client_type'] == 3) {
          webClientId = oauth['client_id'] as String?;
        }
      }
    }

    return GoogleAuthConfig(
      webClientId: webClientId,
      projectId: projectInfo['project_id'] as String?,
      messagingSenderId: projectInfo['project_number'] as String?,
      storageBucket: projectInfo['storage_bucket'] as String?,
      androidApiKey: androidApiKey,
      androidAppId: androidAppId,
    );
  }

  static GoogleAuthConfig? fromGoogleServiceInfoPlist(String raw) {
    String? read(String key) {
      final pattern = RegExp(
        '<key>$key</key>\\s*<string>([^<]+)</string>',
      );
      return pattern.firstMatch(raw)?.group(1)?.trim();
    }

    final iosClientId = read('CLIENT_ID');
    final reversed = read('REVERSED_CLIENT_ID');
    if (iosClientId == null && reversed == null) return null;

    return GoogleAuthConfig(
      iosClientId: iosClientId,
      iosReversedClientId: reversed,
      projectId: read('PROJECT_ID'),
      messagingSenderId: read('GCM_SENDER_ID'),
      storageBucket: read('STORAGE_BUCKET'),
      iosApiKey: read('API_KEY'),
      iosAppId: read('GOOGLE_APP_ID'),
      iosBundleId: read('BUNDLE_ID'),
      webClientId: read('SERVER_CLIENT_ID'),
    );
  }

  static GoogleAuthConfig fromJsonString(String raw) {
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return fromFirebaseClientJson(json);
  }

  String setupHint() {
    return 'Download google-services.json + GoogleService-Info.plist from '
        'Firebase Console (project ai-agent-29433), place them in '
        'assets/config/, then run: dart run tool/sync_google_sign_in.dart';
  }
}
