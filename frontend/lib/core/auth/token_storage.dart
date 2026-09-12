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
  String? _accessMem;
  String? _refreshMem;
  String? _userIdMem;
  bool _accessKnown = false;
  bool _refreshKnown = false;
  bool _userIdKnown = false;

  Future<String?> get accessToken async {
    if (_accessKnown) return _accessMem;
    try {
      _accessMem = await _storage.read(key: _kAccess);
      _accessKnown = true;
    } catch (_) {
      return _accessMem;
    }
    return _accessMem;
  }

  Future<String?> get refreshToken async {
    if (_refreshKnown) return _refreshMem;
    try {
      _refreshMem = await _storage.read(key: _kRefresh);
      _refreshKnown = true;
    } catch (_) {
      return _refreshMem;
    }
    return _refreshMem;
  }

  Future<String?> get userId async {
    if (_userIdKnown) return _userIdMem;
    try {
      _userIdMem = await _storage.read(key: _kUserId);
      _userIdKnown = true;
    } catch (_) {
      return _userIdMem;
    }
    return _userIdMem;
  }

  Future<String?> get deviceId async {
    try {
      return await _storage.read(key: _kDeviceId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get email async {
    try {
      return await _storage.read(key: _kEmail);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get name async {
    try {
      return await _storage.read(key: _kName);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get role async {
    try {
      return await _storage.read(key: _kRole);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get phone async {
    try {
      return await _storage.read(key: _kPhone);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? email,
    String? name,
    String? role,
    String? phone,
  }) async {
    _accessMem = accessToken;
    _refreshMem = refreshToken;
    _userIdMem = userId;
    _accessKnown = true;
    _refreshKnown = true;
    _userIdKnown = true;
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

  Future<void> saveAccessToken(String token) async {
    _accessMem = token;
    _accessKnown = true;
    await _storage.write(key: _kAccess, value: token);
  }

  /// Persist rotated tokens from `/api/auth/refresh-token`.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessMem = accessToken;
    _accessKnown = true;
    await _storage.write(key: _kAccess, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshMem = refreshToken;
      _refreshKnown = true;
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
    _accessMem = null;
    _refreshMem = null;
    _userIdMem = null;
    _accessKnown = true;
    _refreshKnown = true;
    _userIdKnown = true;
    try {
      await Future.wait([
        _storage.delete(key: _kAccess),
        _storage.delete(key: _kRefresh),
        _storage.delete(key: _kUserId),
        _storage.delete(key: _kEmail),
        _storage.delete(key: _kName),
        _storage.delete(key: _kRole),
        _storage.delete(key: _kPhone),
      ]);
    } catch (_) {}
  }
}
