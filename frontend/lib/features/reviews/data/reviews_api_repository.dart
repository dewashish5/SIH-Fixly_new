import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../core/network/api_exception.dart';

class ReviewsApiRepository {
  ReviewsApiRepository({ApiClient? client})
      : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<void> submit({
    required String bookingId,
    required String workerId,
    required int rating,
    String comment = '',
    List<String> traits = const [],
    List<String> photoPaths = const [],
    String reviewerRole = 'customer', // 'customer' or 'worker'
  }) async {
    final map = <String, dynamic>{
      'bookingId': bookingId,
      'workerId': workerId,
      'rating': rating,
      'comment': comment,
      'description': comment,
      'traits': traits.join(','),
      'reviewerRole': reviewerRole,
    };
    if (photoPaths.isNotEmpty) {
      final files = <MultipartFile>[];
      for (final path in photoPaths) {
        if (path.isEmpty) continue;
        files.add(
          await MultipartFile.fromFile(
            path,
            filename: path.split(RegExp(r'[/\\]')).last,
          ),
        );
      }
      map['workPhotos'] = files;
    }
    final form = FormData.fromMap(map);
    final res = await _api.post(
      ApiEndpoints.submitReview(bookingId),
      data: form,
    );
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Review failed');
    }
  }
}

