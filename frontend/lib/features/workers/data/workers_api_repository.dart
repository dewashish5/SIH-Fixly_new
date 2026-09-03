import '../../../core/location/app_location.dart';
import '../../../core/network/api_client.dart';
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
      '/api/workers/',
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
        .map((e) => mapWorker(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<WorkerProfile> fetchWorker(String workerId) async {
    final res = await _api.get('/api/workers/$workerId');
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
    final res = await _api.put('/api/workers/setup-profile', data: body);
    if (res['success'] != true) {
      throw ApiException(
        res['message']?.toString() ?? 'Worker profile update failed',
      );
    }
    return res;
  }

  Future<Map<String, dynamic>> fetchReliability(String workerId) async {
    final res = await _api.get('/api/workers/$workerId/reliability');
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Reliability failed');
    }
    return Map<String, dynamic>.from((res['data'] ?? res['reliability'] ?? {}) as Map);
  }

  Future<Map<String, dynamic>> fetchAvailability() async {
    final res = await _api.get('/api/workers/me/availability');
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Availability failed');
    }
    return Map<String, dynamic>.from(res['data'] as Map? ?? res);
  }

  Future<bool> setOnline(bool isOnline) async {
    final res = await _api.patch('/api/workers/me/availability', data: {
      'isOnline': isOnline,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Availability update failed');
    }
    final data = res['data'];
    if (data is Map) return data['isOnline'] == true;
    return isOnline;
  }

  static WorkerProfile mapWorker(Map<String, dynamic> json) {
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
        0;
    final jobs =
        (profileMap['jobsCompleted'] as num?)?.toInt() ??
        (profileMap['totalJobs'] as num?)?.toInt() ??
        (json['jobsCompleted'] as num?)?.toInt() ??
        0;
    return WorkerProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? 'Worker',
      skills: skills,
      rating: rating,
      jobsCompleted: jobs,
      reliabilityScore: (rating * 20).round().clamp(0, 100),
      avatarUrl: (json['avatar'] ?? profileMap['selfieImageUrl']) as String?,
    );
  }
}
