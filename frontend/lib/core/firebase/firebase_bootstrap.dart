import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/google_auth_config.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;
  static bool _firebaseReady = false;
  static GoogleAuthConfig? _config;

  static GoogleAuthConfig? get config => _config;
  static String? get webClientId => _config?.webClientId;
  static bool get isFirebaseReady => _firebaseReady;

  static Future<void> init() async {
    if (_initialized) return;

    _config = await _loadConfig();
    if (!_config!.hasGoogleSignInIds) {
      throw StateError(_config!.setupHint());
    }

    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _config!.iosClientId
          : null,
      serverClientId: _config!.webClientId,
    );

    await _initFirebaseCoreIfPossible();

    _initialized = true;
  }

  static Future<GoogleAuthConfig> _loadConfig() async {
    var config = GoogleAuthConfig.fromJsonString(
      await rootBundle.loadString('assets/config/firebase_client.json'),
    );

    config = GoogleAuthConfig.merge(
      config,
      await _tryLoadGoogleServicesJson() ?? const GoogleAuthConfig(),
    );
    config = GoogleAuthConfig.merge(
      config,
      await _tryLoadGoogleServiceInfoPlist() ?? const GoogleAuthConfig(),
    );

    return config;
  }

  static Future<GoogleAuthConfig?> _tryLoadGoogleServicesJson() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/config/google-services.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return GoogleAuthConfig.fromGoogleServicesJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<GoogleAuthConfig?> _tryLoadGoogleServiceInfoPlist() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/config/GoogleService-Info.plist',
      );
      return GoogleAuthConfig.fromGoogleServiceInfoPlist(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _initFirebaseCoreIfPossible() async {
    final config = _config!;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? _PlatformFirebase(
            apiKey: config.iosApiKey,
            appId: config.iosAppId,
            iosBundleId: config.iosBundleId,
          )
        : _PlatformFirebase(
            apiKey: config.androidApiKey,
            appId: config.androidAppId,
          );

    if (!platform.isValid ||
        config.projectId == null ||
        config.messagingSenderId == null) {
      debugPrint('Firebase Core skipped — platform keys not configured.');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: platform.apiKey!,
          appId: platform.appId!,
          messagingSenderId: config.messagingSenderId!,
          projectId: config.projectId!,
          storageBucket: config.storageBucket,
          iosBundleId: platform.iosBundleId,
        ),
      );
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase Core init skipped: $e');
    }
  }
}

class _PlatformFirebase {
  const _PlatformFirebase({this.apiKey, this.appId, this.iosBundleId});

  final String? apiKey;
  final String? appId;
  final String? iosBundleId;

  bool get isValid {
    final key = apiKey?.trim();
    final id = appId?.trim();
    if (key == null || id == null) return false;
    return !key.contains('REPLACE_ME') &&
        !id.contains('REPLACE_ME') &&
        !key.contains('123456789') &&
        !id.contains('abcdef');
  }
}
