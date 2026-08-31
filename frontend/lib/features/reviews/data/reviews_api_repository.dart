import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
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
  }) async {
    final form = FormData.fromMap({
      'bookingId': bookingId,
      'workerId': workerId,
      'rating': rating,
      'comment': comment,
      'traits': traits.join(','),
    });
    final res = await _api.post(
      '/api/reviews/$bookingId',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Review failed');
    }
  }
}
