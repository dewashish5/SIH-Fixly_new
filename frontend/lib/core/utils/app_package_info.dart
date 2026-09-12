import 'package:package_info_plus/package_info_plus.dart';

/// Cached app version from `pubspec.yaml` via platform package metadata.
abstract final class AppPackageInfo {
  static PackageInfo? _info;

  static Future<PackageInfo> ensureInitialized() async {
    return _info ??= await PackageInfo.fromPlatform();
  }

  /// Marketing version (`1.0.0` from `version: 1.0.0+1`).
  static String get version => _info?.version ?? '';

  /// Build number (`1` from `version: 1.0.0+1`).
  static String get buildNumber => _info?.buildNumber ?? '';

  /// Display string e.g. `v1.0.0` or `v1.0.0 (1)`.
  static String get displayVersion {
    final v = version;
    if (v.isEmpty) return '';
    final b = buildNumber;
    if (b.isEmpty) return 'v$v';
    return 'v$v ($b)';
  }
}
