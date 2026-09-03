import 'package:dio/dio.dart';

import '../auth/device_id.dart';
import '../auth/token_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required DeviceId deviceId,
    Dio? dio,
  })  : _tokens = tokenStorage,
        _deviceId = deviceId,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 120),
                receiveTimeout: const Duration(seconds: 120),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await _tokens.accessToken;
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          final device = await _deviceId.getOrCreate();
          options.headers['x-device-id'] = device;
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isAuthPath(error.requestOptions.path) &&
              error.requestOptions.extra['retried'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final req = error.requestOptions;
              req.extra['retried'] = true;
              final access = await _tokens.accessToken;
              if (access != null) {
                req.headers['Authorization'] = 'Bearer $access';
              }
              try {
                final response = await _dio.fetch(req);
                return handler.resolve(response);
              } catch (_) {
                await _tokens.clearSession();
                return handler.next(error);
              }
            }
            await _tokens.clearSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokens;
  final DeviceId _deviceId;
  Future<bool>? _refreshInFlight;

  Dio get dio => _dio;

  static bool _isAuthPath(String path) {
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/register') ||
        path.contains('/api/auth/verify-otp') ||
        path.contains('/api/auth/refresh-token') ||
        path.contains('/api/auth/forgot-password') ||
        path.contains('/api/auth/reset-password') ||
        path.contains('/api/auth/google');
  }

  Future<bool> _tryRefresh() {
    final inflight = _refreshInFlight;
    if (inflight != null) return inflight;
    final next = _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = next;
    return next;
  }

  Future<bool> _doRefresh() async {
    final refresh = await _tokens.refreshToken;
    final userId = await _tokens.userId;
    final device = await _deviceId.getOrCreate();
    if (refresh == null ||
        refresh.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return false;
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/refresh-token',
        data: {
          'userId': userId,
          'deviceId': device,
          'refreshToken': refresh,
        },
        options: Options(extra: {'retried': true}),
      );
      final data = res.data;
      if (data == null || data['success'] != true) return false;
      final access = data['accessToken'] as String?;
      if (access == null || access.isEmpty) return false;
      // Backend rotates refresh token — must store the new one or next restore fails.
      final newRefresh = data['refreshToken'] as String?;
      await _tokens.saveTokens(
        accessToken: access,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return res.data ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Options? options,
  }) async {
    try {
      final opts = options ?? Options();
      if (data is FormData) {
        final headers = Map<String, dynamic>.from(opts.headers ?? {});
        headers.remove('Content-Type');
        opts.headers = headers;
        opts.contentType = Headers.multipartFormDataContentType;
      }
      final res = await _dio.post<dynamic>(
        path,
        data: data,
        options: opts,
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(path, data: data);
      return res.data ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(path, data: data);
      return res.data ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    String message = e.message ?? 'Network error';
    final lower = message.toLowerCase();
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (data is String &&
        (data.contains('Cloudflare Tunnel error') ||
            data.contains('Error 1033'))) {
      message =
          'API tunnel is down. Ask host to restart cloudflared + backend.';
    } else if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('no internet') ||
        lower.contains('connection errored')) {
      final host = ApiConfig.baseUrl;
      message =
          'Cannot reach API ($host). Check Wi‑Fi/data and that the server is online.';
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}

/// App-wide singletons bootstrapped in [main].
class ApiServices {
  ApiServices._();

  static late final TokenStorage tokens;
  static late final DeviceId deviceId;
  static late final ApiClient client;

  static Future<void> init() async {
    tokens = TokenStorage();
    deviceId = DeviceId(tokens);
    await deviceId.getOrCreate();
    client = ApiClient(tokenStorage: tokens, deviceId: deviceId);
    // ignore: avoid_print — intentional boot diagnostic for DevTools Network failures
    print('Fixly API_BASE_URL=${ApiConfig.baseUrl}');
  }
}
