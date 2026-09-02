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

  /// Worker onboarding final submit.
  Future<Map<String, dynamic>> submitSetupProfile(
    OnboardingFormData formData,
  ) async {
    final body = WorkerSetupProfileMapper.toBody(formData);
    final res = await _api.put('/api/workers/setup-profile', data: body);
    if (res['success'] != true) {
      throw ApiException(
        res['message']?.toString() ?? 'Worker profile update failed',
      );
    }
    return res;
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
        (json['jobsCompleted'] as num?)?.toInt() ??
        0;
    return WorkerProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? 'Worker',
      skills: skills,
      rating: rating,
      jobsCompleted: jobs,
      reliabilityScore: (rating * 20).round().clamp(0, 100),
      avatarUrl: json['avatar'] as String?,
    );
  }
}
