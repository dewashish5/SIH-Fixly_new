import '../../../core/auth/device_id.dart';
import '../../../core/location/app_location.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../shared/models/models.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;
}

class AuthApiRepository {
  AuthApiRepository({
    ApiClient? client,
    TokenStorage? tokens,
    DeviceId? deviceId,
  })  : _api = client ?? ApiServices.client,
        _tokens = tokens ?? ApiServices.tokens,
        _deviceId = deviceId ?? ApiServices.deviceId;

  final ApiClient _api;
  final TokenStorage _tokens;
  final DeviceId _deviceId;

  static Map<String, dynamic> _locationBody() {
    final loc = AppLocation.instance;
    if (!loc.hasFix) {
      throw ApiException('Location required — enable GPS and try again');
    }
    return {
      'type': 'Point',
      'coordinates': [loc.requireLng, loc.requireLat],
    };
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final res = await _api.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'location': _locationBody(),
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Register failed');
    }
  }

  Future<AuthSession> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final device = await _deviceId.getOrCreate();
    final res = await _api.post('/api/auth/verify-otp', data: {
      'email': email,
      'otp': otp,
      'deviceId': device,
    });
    return _persistSession(res, fallbackMessage: 'OTP verification failed');
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final device = await _deviceId.getOrCreate();
    final res = await _api.post('/api/auth/login', data: {
      'email': email,
      'password': password,
      'deviceId': device,
      'location': _locationBody(),
    });
    return _persistSession(res, fallbackMessage: 'Login failed');
  }

  Future<AuthSession> googleLogin({
    required String email,
    required String name,
    String? avatar,
    required String role,
  }) async {
    final device = await _deviceId.getOrCreate();
    final res = await _api.post('/api/auth/google', data: {
      'email': email,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      'deviceId': device,
      'location': _locationBody(),
    });
    return _persistSession(res, fallbackMessage: 'Google login failed');
  }

  Future<String> refreshAccessToken() async {
    final refresh = await _tokens.refreshToken;
    final userId = await _tokens.userId;
    final device = await _deviceId.getOrCreate();
    if (refresh == null || userId == null) {
      throw ApiException('No refresh session');
    }
    final res = await _api.post('/api/auth/refresh-token', data: {
      'userId': userId,
      'deviceId': device,
      'refreshToken': refresh,
    });
    final access = res['accessToken'] as String?;
    if (res['success'] != true || access == null) {
      throw ApiException(res['message']?.toString() ?? 'Refresh failed');
    }
    await _tokens.saveAccessToken(access);
    return access;
  }

  Future<void> forgotPassword(String email) async {
    final res = await _api.post('/api/auth/forgot-password', data: {
      'email': email,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Request failed');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _api.post('/api/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Reset failed');
    }
  }

  Future<void> logout() async {
    final userId = await _tokens.userId;
    final device = await _deviceId.getOrCreate();
    if (userId != null) {
      try {
        await _api.post('/api/auth/logout', data: {
          'userId': userId,
          'deviceId': device,
        });
      } catch (_) {
        // Still clear local session.
      }
    }
    await _tokens.clearSession();
  }

  Future<AuthSession?> restoreSession() async {
    final refresh = await _tokens.refreshToken;
    final userId = await _tokens.userId;
    if (refresh == null || userId == null) return null;
    try {
      await refreshAccessToken();
      final roleStr = await _tokens.role;
      final email = await _tokens.email;
      final name = await _tokens.name;
      final phone = await _tokens.phone;
      return AuthSession(
        user: AppUser(
          id: userId,
          name: name ?? 'Fixly User',
          phone: phone ?? '',
          email: email ?? '',
          role: roleStr == 'worker' ? UserRole.worker : UserRole.customer,
        ),
        accessToken: (await _tokens.accessToken) ?? '',
        refreshToken: refresh,
      );
    } catch (_) {
      await _tokens.clearSession();
      return null;
    }
  }

  Future<AuthSession> _persistSession(
    Map<String, dynamic> res, {
    required String fallbackMessage,
  }) async {
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? fallbackMessage);
    }
    final access = res['accessToken'] as String?;
    final refresh = res['refreshToken'] as String?;
    final userJson = res['user'] as Map<String, dynamic>?;
    if (access == null || refresh == null || userJson == null) {
      throw ApiException(fallbackMessage);
    }
    final user = mapUser(userJson);
    await _tokens.saveSession(
      accessToken: access,
      refreshToken: refresh,
      userId: user.id,
      email: user.email,
      name: user.name,
      role: user.role == UserRole.worker ? 'worker' : 'customer',
      phone: user.phone,
    );
    return AuthSession(user: user, accessToken: access, refreshToken: refresh);
  }

  static AppUser mapUser(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?) ?? 'customer';
    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? 'Fixly User',
      phone: (json['phone'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: roleStr == 'worker' ? UserRole.worker : UserRole.customer,
      avatar: json['avatar'] as String?,
    );
  }
}
