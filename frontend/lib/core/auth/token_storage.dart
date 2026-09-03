import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kAccess = 'fixly_access_token';
  static const _kRefresh = 'fixly_refresh_token';
  static const _kUserId = 'fixly_user_id';
  static const _kDeviceId = 'fixly_device_id';
  static const _kEmail = 'fixly_user_email';
  static const _kName = 'fixly_user_name';
  static const _kRole = 'fixly_user_role';
  static const _kPhone = 'fixly_user_phone';

  final FlutterSecureStorage _storage;

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get userId => _storage.read(key: _kUserId);
  Future<String?> get deviceId => _storage.read(key: _kDeviceId);
  Future<String?> get email => _storage.read(key: _kEmail);
  Future<String?> get name => _storage.read(key: _kName);
  Future<String?> get role => _storage.read(key: _kRole);
  Future<String?> get phone => _storage.read(key: _kPhone);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? email,
    String? name,
    String? role,
    String? phone,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
      _storage.write(key: _kUserId, value: userId),
      if (email != null) _storage.write(key: _kEmail, value: email),
      if (name != null) _storage.write(key: _kName, value: name),
      if (role != null) _storage.write(key: _kRole, value: role),
      if (phone != null) _storage.write(key: _kPhone, value: phone),
    ]);
  }

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccess, value: token);

  /// Persist rotated tokens from `/api/auth/refresh-token`.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _kRefresh, value: refreshToken);
    }
  }

  Future<void> saveProfile({String? name, String? phone}) async {
    await Future.wait([
      if (name != null) _storage.write(key: _kName, value: name),
      if (phone != null) _storage.write(key: _kPhone, value: phone),
    ]);
  }

  Future<void> saveDeviceId(String id) =>
      _storage.write(key: _kDeviceId, value: id);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kUserId),
      _storage.delete(key: _kEmail),
      _storage.delete(key: _kName),
      _storage.delete(key: _kRole),
      _storage.delete(key: _kPhone),
    ]);
  }
}
