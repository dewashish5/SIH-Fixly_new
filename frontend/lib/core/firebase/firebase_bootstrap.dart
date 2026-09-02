import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;
  static String? _webClientId;

  static String? get webClientId => _webClientId;

  static Future<void> init() async {
    if (_initialized) return;

    final raw = await rootBundle.loadString('assets/config/firebase_client.json');
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    final projectId = json['projectId'] as String? ?? '';
    final storageBucket = json['storageBucket'] as String?;
    final messagingSenderId = json['messagingSenderId'] as String? ?? '';
    final googleSignIn = Map<String, dynamic>.from(
      (json['googleSignIn'] as Map?) ?? const {},
    );
    _webClientId = googleSignIn['webClientId'] as String?;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? Map<String, dynamic>.from((json['ios'] as Map?) ?? const {})
        : Map<String, dynamic>.from((json['android'] as Map?) ?? const {});

    final apiKey = platform['apiKey'] as String? ?? '';
    final appId = platform['appId'] as String? ?? '';

    if (projectId.isEmpty ||
        apiKey.contains('REPLACE_ME') ||
        appId.contains('REPLACE_ME') ||
        messagingSenderId.contains('REPLACE_ME') ||
        (_webClientId?.contains('REPLACE_ME') ?? true)) {
      throw StateError(
        'Firebase client config incomplete. Fill assets/config/firebase_client.json '
        'from Firebase Console → Project settings → Your apps, then add the Web '
        'OAuth client ID under googleSignIn.webClientId.',
      );
    }

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        iosBundleId: platform['iosBundleId'] as String?,
      ),
    );

    await GoogleSignIn.instance.initialize(
      serverClientId: _webClientId,
    );

    _initialized = true;
  }
}
