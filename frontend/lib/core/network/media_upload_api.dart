import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Uploads a local file to `POST /api/upload` → Cloudinary URL.
class MediaUploadApi {
  MediaUploadApi({ApiClient? client}) : _api = client ?? ApiServices.client;

  final ApiClient _api;

  /// Returns [path] unchanged if already http(s). Null/empty → null.
  Future<String?> uploadIfLocal(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return uploadFile(trimmed);
  }

  Future<String> uploadFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ApiException('File not found: $path');
    }
    final name = path.split(RegExp(r'[/\\]')).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: name),
    });
    final res = await _api.post('/api/upload', data: form);
    if (res['success'] != true || res['url'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Upload failed');
    }
    return res['url'].toString();
  }
}
