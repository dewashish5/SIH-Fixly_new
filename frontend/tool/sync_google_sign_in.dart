// Sync Firebase Google Sign-In config into Flutter + native projects.
//
// Usage (from frontend/):
//   dart run tool/sync_google_sign_in.dart
//
// Requires:
//   assets/config/google-services.json
//   assets/config/GoogleService-Info.plist

import 'dart:convert';
import 'dart:io';

import 'package:fixly/core/auth/google_auth_config.dart';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run from frontend/ directory.');
    exit(1);
  }

  final gsPath = File('assets/config/google-services.json');
  final plistPath = File('assets/config/GoogleService-Info.plist');
  if (!gsPath.existsSync()) {
    stderr.writeln('Missing ${gsPath.path}');
    exit(1);
  }
  if (!plistPath.existsSync()) {
    stderr.writeln('Missing ${plistPath.path}');
    exit(1);
  }

  final gsJson = Map<String, dynamic>.from(
    jsonDecode(gsPath.readAsStringSync()) as Map,
  );
  final gsConfig = GoogleAuthConfig.fromGoogleServicesJson(gsJson);
  if (gsConfig == null || !gsConfig.hasGoogleSignInIds) {
    stderr.writeln(
      'google-services.json has no web OAuth client (client_type 3). '
      'Enable Google Sign-In in Firebase and re-download the file.',
    );
    exit(1);
  }

  final plistRaw = plistPath.readAsStringSync();
  final iosConfig =
      GoogleAuthConfig.fromGoogleServiceInfoPlist(plistRaw) ??
          const GoogleAuthConfig();
  if (iosConfig.iosClientId == null || iosConfig.iosReversedClientId == null) {
    stderr.writeln(
      'GoogleService-Info.plist missing CLIENT_ID or REVERSED_CLIENT_ID.',
    );
    exit(1);
  }

  final merged = GoogleAuthConfig.merge(gsConfig, iosConfig);

  await _writeFirebaseClientJson(merged);
  await _copyAndroidGoogleServices(gsPath);
  await _patchIosInfoPlist(iosConfig);

  stdout.writeln('Google Sign-In config synced.');
  stdout.writeln('  webClientId: ${merged.webClientId}');
  stdout.writeln('  iosClientId: ${merged.iosClientId}');
  stdout.writeln('Next: flutter pub get && flutter run');
}

Future<void> _writeFirebaseClientJson(GoogleAuthConfig config) async {
  final out = {
    'projectId': config.projectId,
    'storageBucket': config.storageBucket,
    'messagingSenderId': config.messagingSenderId,
    'android': {
      'apiKey': config.androidApiKey,
      'appId': config.androidAppId,
    },
    'ios': {
      'apiKey': config.iosApiKey,
      'appId': config.iosAppId,
      'iosBundleId': config.iosBundleId ?? 'com.example.fixly',
    },
    'googleSignIn': {
      'webClientId': config.webClientId,
      'iosClientId': config.iosClientId,
      'iosReversedClientId': config.iosReversedClientId,
    },
  };

  final file = File('assets/config/firebase_client.json');
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
}

Future<void> _copyAndroidGoogleServices(File source) async {
  final target = File('android/app/google-services.json');
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(source.readAsStringSync());
}

Future<void> _patchIosInfoPlist(GoogleAuthConfig config) async {
  final infoPlist = File('ios/Runner/Info.plist');
  var content = infoPlist.readAsStringSync();

  content = _upsertPlistString(content, 'GIDClientID', config.iosClientId!);
  content = _upsertPlistString(
    content,
    'GIDServerClientID',
    config.webClientId ?? config.iosClientId!,
  );
  content = _upsertGoogleUrlScheme(content, config.iosReversedClientId!);

  infoPlist.writeAsStringSync(content);
}

String _upsertPlistString(String content, String key, String value) {
  final pattern = RegExp(
    '<key>$key</key>\\s*<string>[^<]*</string>',
  );
  final replacement = '<key>$key</key>\n\t<string>$value</string>';
  if (pattern.hasMatch(content)) {
    return content.replaceFirst(pattern, replacement);
  }
  final insertBefore = content.lastIndexOf('</dict>');
  if (insertBefore < 0) return content;
  final insertion = '\t<key>$key</key>\n\t<string>$value</string>\n';
  return content.replaceRange(insertBefore, insertBefore, insertion);
}

String _upsertGoogleUrlScheme(String content, String reversedClientId) {
  const marker = '<!-- GOOGLE_SIGN_IN_URL_SCHEME -->';
  final block = '''
\t$marker
\t<key>CFBundleURLTypes</key>
\t<array>
\t\t<dict>
\t\t\t<key>CFBundleTypeRole</key>
\t\t\t<string>Editor</string>
\t\t\t<key>CFBundleURLSchemes</key>
\t\t\t<array>
\t\t\t\t<string>$reversedClientId</string>
\t\t\t</array>
\t\t</dict>
\t</array>''';

  if (content.contains(marker)) {
    final start = content.indexOf(marker);
    final end = content.indexOf('</array>', start);
    if (end < 0) return content;
    return content.replaceRange(start, end + '</array>'.length, block.trim());
  }

  final insertBefore = content.lastIndexOf('</dict>');
  return content.replaceRange(insertBefore, insertBefore, '\n$block\n');
}
