import '../auth/device_id.dart';
import '../network/api_client.dart';
import '../network/api_enpoints.dart';

class NotificationTokenService {
  NotificationTokenService({ApiClient? client, DeviceId? deviceId})
    : _client = client ?? ApiServices.client,
      _deviceId = deviceId ?? ApiServices.deviceId;

  final ApiClient _client;
  final DeviceId _deviceId;

  Future<void> register({
    required String token,
    String? platform,
    String? appVersion,
    String? locale,
  }) async {
    await _client.post(
      ApiEndpoints.registerDeviceToken,
      data: {
        'token': token,
        'deviceId': await _deviceId.getOrCreate(),
        'platform': platform ?? 'unknown',
        'appVersion': appVersion,
        'locale': locale ?? 'en',
      },
    );
  }

  Future<void> remove(String token) async {
    await _client.delete(
      ApiEndpoints.removeDeviceToken,
      data: {'token': token},
    );
  }
}
