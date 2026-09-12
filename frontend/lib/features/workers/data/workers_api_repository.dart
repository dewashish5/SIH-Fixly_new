import '../../../core/location/app_location.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/models.dart';
import '../../worker/data/worker_setup_profile_mapper.dart';

class WorkersApiRepository {
  WorkersApiRepository({ApiClient? client})
    : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<WorkersPage> fetchNearbyPage({
    double? lng,
    double? lat,
    String? category,
    String sortBy = 'nearest',
    int offset = 0,
    int limit = 5,
  }) async {
    final loc = AppLocation.instance;
    final useLng = lng ?? (loc.hasFix ? loc.requireLng : null);
    final useLat = lat ?? (loc.hasFix ? loc.requireLat : null);
    if (useLng == null || useLat == null) {
      throw ApiException('Location required to find nearby workers');
    }
    final res = await _api.get(
      ApiEndpoints.workers,
      query: {
        'lng': useLng,
        'lat': useLat,
        'sortBy': sortBy,
        'offset': offset,
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Workers failed');
    }
    final list = res['workers'];
    final workers = list is List
        ? list
              .whereType<Map>()
              .map(
                (e) => mapWorker(Map<String, dynamic>.from(e), useLat, useLng),
              )
              .toList()
        : <WorkerProfile>[];
    return WorkersPage(
      workers: workers,
      hasMore: res['hasMore'] == true,
      nextOffset:
          (res['nextOffset'] as num?)?.toInt() ?? offset + workers.length,
    );
  }

  Future<List<WorkerProfile>> fetchNearby({
    double? lng,
    double? lat,
    String? category,
    String sortBy = 'nearest',
  }) async {
    final loc = AppLocation.instance;
    final useLng = lng ?? (loc.hasFix ? loc.requireLng : null);
    final useLat = lat ?? (loc.hasFix ? loc.requireLat : null);
    if (useLng == null || useLat == null) {
      throw ApiException('Location required to find nearby workers');
    }
    return (await fetchNearbyPage(
      lng: useLng,
      lat: useLat,
      category: category,
      sortBy: sortBy,
    )).workers;
  }

  Future<WorkerProfile> fetchWorker(String workerId) async {
    final res = await _api.get(ApiEndpoints.workerById(workerId));
    final rawWorker = res['worker'] ?? res['data'] ?? res['user'];
    if (res['success'] != true || rawWorker is! Map) {
      throw ApiException(res['message']?.toString() ?? 'Worker not found');
    }
    return mapWorker(Map<String, dynamic>.from(rawWorker));
  }

  /// Last onboarding step: flat JSON + base64 media → setup-profile.
  Future<Map<String, dynamic>> submitSetupProfile(
    OnboardingFormData formData,
  ) async {
    final body = await WorkerSetupProfileMapper.toBody(formData);
    final res = await _api.put(ApiEndpoints.setupProfile, data: body);
    if (res['success'] != true) {
      throw ApiException(
        res['message']?.toString() ?? 'Worker profile update failed',
      );
    }
    return res;
  }

  Future<Map<String, dynamic>> fetchReliability(String workerId) async {
    final res = await _api.get(ApiEndpoints.workerReliability(workerId));
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Reliability failed');
    }
    return Map<String, dynamic>.from(
      (res['data'] ?? res['reliability'] ?? {}) as Map,
    );
  }

  Future<Map<String, dynamic>> fetchAvailability() async {
    final res = await _api.get(ApiEndpoints.workerAvailability);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Availability failed');
    }
    return Map<String, dynamic>.from(res['data'] as Map? ?? res);
  }

  Future<bool> setOnline(bool isOnline) async {
    final res = await _api.patch(
      ApiEndpoints.workerAvailability,
      data: {'isOnline': isOnline},
    );
    if (res['success'] != true) {
      throw ApiException(
        res['message']?.toString() ?? 'Availability update failed',
      );
    }
    final data = res['data'];
    if (data is Map) return data['isOnline'] == true;
    return isOnline;
  }

  Future<Map<String, dynamic>> fetchWorkerRates() async {
    final res = await _api.get('/api/workers/me/rates');
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Failed to fetch rates');
    }
    return Map<String, dynamic>.from(res['data'] as Map? ?? res);
  }

  Future<void> updateWorkerRates(List<Map<String, dynamic>> rates) async {
    final res = await _api.put(
      '/api/workers/me/rates',
      data: {'categoryRates': rates},
    );
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Failed to update rates');
    }
  }

  Future<Map<String, dynamic>> fetchMyCooperativeMembership() async {
    final res = await _api.get('/api/cooperative/my-society');
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Failed to fetch cooperative details');
    }
    return Map<String, dynamic>.from(res['data'] as Map? ?? res);
  }

  static WorkerProfile mapWorker(
    Map<String, dynamic> json, [
    double? userLat,
    double? userLng,
  ]) {
    final profile = json['workerProfile'];
    final profileMap = profile is Map
        ? Map<String, dynamic>.from(profile)
        : <String, dynamic>{};
    final skillsRaw = profileMap['skills'] ?? json['skills'];
    final skills = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final rating =
        (profileMap['rating'] as num?)?.toDouble() ??
        (json['rating'] as num?)?.toDouble() ??
        0.0;
    final jobs =
        (profileMap['jobsCompleted'] as num?)?.toInt() ??
        (profileMap['totalJobs'] as num?)?.toInt() ??
        (json['jobsCompleted'] as num?)?.toInt() ??
        (json['totalJobs'] as num?)?.toInt() ??
        0;
    final hourlyRate =
        (profileMap['rate'] as num?)?.toDouble() ??
        (profileMap['hourlyRate'] as num?)?.toDouble() ??
        (json['rate'] as num?)?.toDouble() ??
        0.0;
    final category = (profileMap['category'] ?? json['category'])?.toString();
    final bio = (profileMap['bio'] ?? json['bio'])?.toString();
    final experienceYears = (profileMap['experienceYears'] as num?)?.toInt();
    final reviewsRaw = json['reviews'] ?? profileMap['reviews'];
    final reviews = reviewsRaw is List
        ? reviewsRaw.whereType<Map>().map(_mapReview).toList()
        : <WorkerReview>[];
    final reviewCount =
        (json['reviewCount'] as num?)?.toInt() ??
        (json['totalReviews'] as num?)?.toInt() ??
        (profileMap['reviewCount'] as num?)?.toInt() ??
        (profileMap['totalReviews'] as num?)?.toInt() ??
        reviews.length;
    final reliabilityRaw = json['reliability'];
    final reliability = reliabilityRaw is Map
        ? Map<String, dynamic>.from(reliabilityRaw)
        : <String, dynamic>{};
    final kycRaw = json['kycDocuments'];
    final kyc = kycRaw is Map ? Map<String, dynamic>.from(kycRaw) : {};

    // Distance calculation if coordinates are present
    double? distanceKm = (json['distanceKm'] as num?)?.toDouble();
    final loc = json['location'];
    if (loc is Map && userLat != null && userLng != null) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        final wLng = (coords[0] as num).toDouble();
        final wLat = (coords[1] as num).toDouble();
        final dy = (wLat - userLat) * 111.0;
        final dx = (wLng - userLng) * 111.0;
        distanceKm ??= (dx * dx + dy * dy) > 0 ? (dx.abs() + dy.abs()) : 0.4;
        if (distanceKm < 0.1) distanceKm = 0.4;
      }
    }

    final categoriesRaw = profileMap['categories'] ?? json['categories'] ?? profileMap['categoryRates'] ?? json['categoryRates'];
    final categories = <String>[];
    if (categoriesRaw is List) {
      for (final c in categoriesRaw) {
        if (c is String && c.trim().isNotEmpty) {
          categories.add(c.trim());
        } else if (c is Map && c['category'] != null) {
          categories.add(c['category'].toString().trim());
        }
      }
    }
    if (category != null && category.isNotEmpty && !categories.any((c) => c.toLowerCase() == category.toLowerCase())) {
      categories.insert(0, category);
    }

    return WorkerProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? 'Worker',
      skills: skills,
      rating: rating,
      jobsCompleted: jobs,
      reliabilityScore:
          (reliability['score'] as num?)?.toInt() ??
          (rating * 20).round().clamp(0, 100),
      avatarUrl:
          (json['avatar'] ??
                  profileMap['selfieImageUrl'] ??
                  profileMap['identityProofPhoto'])
              ?.toString(),
      category: category,
      categories: categories,
      title: (json['title'] ?? profileMap['title'])?.toString(),
      hourlyRate: hourlyRate > 0 ? hourlyRate : null,
      minimumCharge: (json['minimumCharge'] as num?)?.toDouble(),
      rateFormatted: json['rateFormatted']
          ?.toString()
          .replaceAll(RegExp(r'\s*/\s*hr\b', caseSensitive: false), ' base price')
          .replaceAll(RegExp(r'\s*/\s*hour\b', caseSensitive: false), ' base price'),
      distanceKm: distanceKm != null
          ? double.parse(distanceKm.toStringAsFixed(1))
          : null,
      distanceFormatted: json['distanceFormatted']?.toString(),
      isOnline: json['isOnline'] == true || profileMap['isOnline'] == true,
      isAvailable:
          json['isAvailable'] == true ||
          profileMap['isAvailable'] == true ||
          profileMap['isOnline'] == true ||
          json['isOnline'] == true,
      reviewCount: reviewCount,
      reviews: reviews,
      onTimeArrival: (reliability['onTimeArrival'] as num?)?.toDouble(),
      completionRate: (reliability['completionRate'] as num?)?.toDouble(),
      customerFeedback: (reliability['customerFeedback'] as num?)?.toDouble(),
      cancellationRate: (reliability['cancellationRate'] as num?)?.toDouble(),
      serviceRadiusKm:
          (profileMap['serviceRadiusKm'] as num?)?.toDouble() ??
          (json['serviceRadiusKm'] as num?)?.toDouble(),
      kycStatus: kyc['status']?.toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      bio: bio,
      experienceYears: experienceYears,
      isVerified: json['isVerified'] != false,
      insured: json['insured'] == true || profileMap['insured'] == true,
      federationId: (profileMap['federationId'] ?? json['federationId'])?.toString(),
      federationName: (profileMap['federationName'] ?? json['federationName'] ?? 'National Labour Cooperative Federation (NLCF)')?.toString(),
      includedTasks: (profileMap['includedTasks'] is List
          ? (profileMap['includedTasks'] as List).map((e) => e.toString()).toList()
          : (json['includedTasks'] is List
              ? (json['includedTasks'] as List).map((e) => e.toString()).toList()
              : const <String>[])),
      excludedTasks: (profileMap['excludedTasks'] is List
          ? (profileMap['excludedTasks'] as List).map((e) => e.toString()).toList()
          : (json['excludedTasks'] is List
              ? (json['excludedTasks'] as List).map((e) => e.toString()).toList()
              : const <String>[])),
    );
  }

  static WorkerReview _mapReview(Map review) {
    final reviewer = review['reviewer'] ?? review['customer'];
    final reviewerMap = reviewer is Map ? reviewer : const <String, dynamic>{};
    return WorkerReview(
      reviewerName:
          (review['reviewerName'] ??
                  review['customerName'] ??
                  reviewerMap['name'] ??
                  'Customer')
              .toString(),
      rating: (review['rating'] as num?)?.toDouble() ?? 0,
      comment: (review['comment'] ?? review['text'] ?? review['review'] ?? '')
          .toString(),
      createdAt: DateTime.tryParse(
        (review['createdAt'] ?? review['date'] ?? '').toString(),
      ),
    );
  }
}

class WorkersPage {
  const WorkersPage({
    required this.workers,
    required this.hasMore,
    required this.nextOffset,
  });

  final List<WorkerProfile> workers;
  final bool hasMore;
  final int nextOffset;
}
