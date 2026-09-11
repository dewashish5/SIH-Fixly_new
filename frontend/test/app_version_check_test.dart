import 'package:flutter_test/flutter_test.dart';
import 'package:fixly/core/network/app_version_api.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'fixly',
      packageName: 'com.example.fixly',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('AppVersionCheck.fromJson maps update flags', () {
    final check = AppVersionCheck.fromJson({
      'isUpdateAvailable': true,
      'forceUpdate': true,
      'updateUrl': 'https://play.google.com/store/apps/details?id=com.fixly.app',
      'updateTitle': 'Update Available',
      'updateMessage': 'Please update',
      'appVersion': '2.0.0',
      'clientAppVersion': '1.0.0',
    });
    expect(check.isUpdateAvailable, isTrue);
    expect(check.forceUpdate, isTrue);
    expect(check.updateUrl, contains('play.google.com'));
    expect(check.updateTitle, 'Update Available');
    expect(check.latestAppVersion, '2.0.0');
    expect(check.clientAppVersion, '1.0.0');
  });

  test('AppVersionCheck.fromJson defaults when fields missing', () {
    final check = AppVersionCheck.fromJson({'success': true});
    expect(check.isUpdateAvailable, isFalse);
    expect(check.forceUpdate, isFalse);
    expect(check.updateUrl, isEmpty);
  });
}
