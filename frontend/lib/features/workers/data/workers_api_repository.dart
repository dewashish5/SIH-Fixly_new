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
    final res = await _api.get(
      ApiEndpoints.workers,
      query: {
        'lng': useLng,
        'lat': useLat,
        'sortBy': sortBy,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Workers failed');
    }
    final list = res['workers'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => mapWorker(Map<String, dynamic>.from(e), useLat, useLng))
        .toList();
  }

  Future<WorkerProfile> fetchWorker(String workerId) async {
    final res = await _api.get(ApiEndpoints.workerById(workerId));
    if (res['success'] != true || res['worker'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Worker not found');
    }
    return mapWorker(Map<String, dynamic>.from(res['worker'] as Map));
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
    return Map<String, dynamic>.from((res['data'] ?? res['reliability'] ?? {}) as Map);
  }

  Future<Map<String, dynamic>> fetchAvailability() async {
    final res = await _api.get(ApiEndpoints.workerAvailability);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Availability failed');
    }
    return Map<String, dynamic>.from(res['data'] as Map? ?? res);
  }

  Future<bool> setOnline(bool isOnline) async {
    final res = await _api.patch(ApiEndpoints.workerAvailability, data: {
      'isOnline': isOnline,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Availability update failed');
    }
    final data = res['data'];
    if (data is Map) return data['isOnline'] == true;
    return isOnline;
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
        5.0;
    final jobs =
        (profileMap['jobsCompleted'] as num?)?.toInt() ??
        (profileMap['totalJobs'] as num?)?.toInt() ??
        (json['jobsCompleted'] as num?)?.toInt() ??
        0;
    final hourlyRate =
        (profileMap['rate'] as num?)?.toDouble() ??
        (profileMap['hourlyRate'] as num?)?.toDouble() ??
        0.0;
    final category =
        (profileMap['category'] ?? json['category'])?.toString();
    final bio = (profileMap['bio'] ?? json['bio'])?.toString();
    final experienceYears = (profileMap['experienceYears'] as num?)?.toInt();

    // Distance calculation if coordinates are present
    double? distanceKm;
    final loc = json['location'];
    if (loc is Map && userLat != null && userLng != null) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        final wLng = (coords[0] as num).toDouble();
        final wLat = (coords[1] as num).toDouble();
        final dy = (wLat - userLat) * 111.0;
        final dx = (wLng - userLng) * 111.0;
        distanceKm = (dx * dx + dy * dy) > 0 ? (dx.abs() + dy.abs()) : 0.4;
        if (distanceKm < 0.1) distanceKm = 0.4;
      }
    }

    return WorkerProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? 'Worker',
      skills: skills,
      rating: rating,
      jobsCompleted: jobs,
      reliabilityScore: (rating * 20).round().clamp(0, 100),
      avatarUrl: (json['avatar'] ??
              profileMap['selfieImageUrl'] ??
              profileMap['identityProofPhoto'])
          ?.toString(),
      category: category,
      hourlyRate: hourlyRate > 0 ? hourlyRate : null,
      distanceKm: distanceKm != null ? double.parse(distanceKm.toStringAsFixed(1)) : null,
      bio: bio,
      experienceYears: experienceYears,
      isVerified: json['isVerified'] != false,
      insured: json['insured'] == true || profileMap['insured'] == true,
    );
  }
}
