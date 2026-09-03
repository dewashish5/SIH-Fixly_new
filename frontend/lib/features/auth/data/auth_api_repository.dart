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

  static Map<String, dynamic>? _locationBody() {
    return AppLocation.instance.toGeoJsonPointOrNull();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
  }) async {
    final res = await _api.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
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
    required String phone,
    String? avatar,
    required String role,
  }) async {
    final device = await _deviceId.getOrCreate();
    final effectiveAvatar = (avatar != null && avatar.trim().isNotEmpty)
        ? avatar.trim()
        : 'https://lh3.googleusercontent.com/a/default-user';

    final res = await _api.post('/api/auth/google', data: {
      'email': email,
      'name': name,
      'avatar': effectiveAvatar,
      'role': role,
      'phone': phone,
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
    if (res['success'] != true || access == null || access.isEmpty) {
      throw ApiException(res['message']?.toString() ?? 'Refresh failed');
    }
    final newRefresh = res['refreshToken'] as String?;
    await _tokens.saveTokens(
      accessToken: access,
      refreshToken: newRefresh,
    );
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
    _api.clearGetCache();
  }

  Future<AuthSession?>? _restoreInFlight;

  Future<AuthSession?> restoreSession() {
    final inflight = _restoreInFlight;
    if (inflight != null) return inflight;
    final next = _restoreSessionBody().whenComplete(() {
      _restoreInFlight = null;
    });
    _restoreInFlight = next;
    return next;
  }

  Future<AuthSession?> _restoreSessionBody() async {
    final refresh = await _tokens.refreshToken;
    final userId = await _tokens.userId;
    if (refresh == null ||
        refresh.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }
    try {
      // Access token first. Interceptor refreshes only on 401.
      final user = await fetchMe();
      return AuthSession(
        user: user,
        accessToken: (await _tokens.accessToken) ?? '',
        refreshToken: (await _tokens.refreshToken) ?? refresh,
      );
    } catch (_) {
      await _tokens.clearSession();
      _api.clearGetCache();
      return null;
    }
  }

  Future<AppUser> fetchMe() async {
    final userJson = await fetchMeUserJson();
    final user = mapUser(userJson);
    await _tokens.saveProfile(name: user.name, phone: user.phone);
    return user;
  }

  /// Full `/api/auth/me` user object (includes workerProfile / KYC fields).
  Future<Map<String, dynamic>> fetchMeUserJson() async {
    final res = await _api.get('/api/auth/me');
    if (res['success'] != true || res['user'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Profile fetch failed');
    }
    return Map<String, dynamic>.from(res['user'] as Map);
  }

  /// Map application verification tracker from `/api/auth/me` user payload.
  static KycReviewStatus mapKycStatus(Map<String, dynamic> user) {
    final profileRaw = user['workerProfile'];
    final profile = profileRaw is Map
        ? Map<String, dynamic>.from(profileRaw)
        : <String, dynamic>{};
    final hasProfile = profile.isNotEmpty;

    final kycDocsRaw = user['kycDocuments'];
    final kycDocs = kycDocsRaw is Map
        ? Map<String, dynamic>.from(kycDocsRaw)
        : <String, dynamic>{};

    final raw = (user['kycStatus'] ??
            user['verificationStatus'] ??
            kycDocs['status'] ??
            profile['kycStatus'] ??
            profile['status'] ??
            profile['verificationStatus'] ??
            profile['profileStatus'] ??
            '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    // Decline must win over profile heuristics.
    if (raw == 'rejected' ||
        raw == 'declined' ||
        raw == 'denied' ||
        raw == 'rejected_by_admin') {
      return KycReviewStatus.rejected;
    }

    // KYC approved only when email/KYC flag set AND worker finished setup.
    if (user['isVerified'] == true && hasProfile) {
      return KycReviewStatus.approved;
    }

    switch (raw) {
      case 'approved':
      case 'verified':
      case 'active':
      case 'completed':
        return KycReviewStatus.approved;
      case 'in_review':
      case 'inreview':
      case 'pending':
      case 'under_review':
      case 'review':
        return KycReviewStatus.inReview;
      case 'submitted':
      case 'pending_review':
      case 'pendingreview':
        return KycReviewStatus.submitted;
    }

    final badges = profile['badges'];
    if (badges is List) {
      final joined = badges.map((e) => e.toString().toLowerCase()).join(' ');
      if (joined.contains('verified') ||
          joined.contains('approved') ||
          joined.contains('background checked')) {
        return KycReviewStatus.approved;
      }
    }

    // Docs approved on profile → still wait for user.isVerified for dashboard.
    final docs = profile['identityDocuments'];
    if (docs is List && docs.isNotEmpty) {
      final allApproved = docs.every((d) {
        if (d is! Map) return false;
        return (d['status']?.toString().toUpperCase() ?? '') == 'APPROVED';
      });
      if (allApproved) return KycReviewStatus.inReview;
      return KycReviewStatus.submitted;
    }

    if (profile.isNotEmpty) {
      final selfieOk = profile['selfieVerified'] == true;
      final hasDocs = profile['aadhaarNumber'] != null ||
          profile['panNumber'] != null ||
          profile['govermentIdNumber'] != null ||
          (profile['identityDocuments'] is List &&
              (profile['identityDocuments'] as List).isNotEmpty);
      if (selfieOk && hasDocs) return KycReviewStatus.inReview;
      return KycReviewStatus.submitted;
    }

    return KycReviewStatus.submitted;
  }

  /// Admin decline text from `/api/auth/me` (`kycDocuments.declineReason`).
  static String? mapDeclineReason(Map<String, dynamic> user) {
    final kycDocsRaw = user['kycDocuments'];
    if (kycDocsRaw is! Map) return null;
    final reason = kycDocsRaw['declineReason']?.toString().trim();
    if (reason == null || reason.isEmpty) return null;
    return reason;
  }

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
    String? avatar,
    String? preferredLanguage,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? bio,
    String? category,
    List<String>? categories,
    List<String>? skills,
    double? hourlyRate,
    int? experienceYears,
    String? workAddress,
    String? gender,
    String? upiId,
    String? homeCity,
    String? homePincode,
    bool isWorker = false,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'phone': phone,
    };
    if (avatar != null) payload['avatar'] = avatar;
    if (preferredLanguage != null) payload['preferredLanguage'] = preferredLanguage;

    if (emergencyContactName != null || emergencyContactPhone != null || emergencyContactRelation != null) {
      payload['emergencyContact'] = {
        'name': emergencyContactName ?? '',
        'phone': emergencyContactPhone ?? '',
        'relation': emergencyContactRelation ?? '',
      };
    }

    if (isWorker) {
      if (bio != null) payload['bio'] = bio;
      if (category != null) payload['category'] = category;
      if (categories != null) payload['categories'] = categories;
      if (skills != null) payload['skills'] = skills;
      if (hourlyRate != null) payload['hourlyRate'] = hourlyRate;
      if (experienceYears != null) payload['experienceYears'] = experienceYears;
      if (workAddress != null) payload['workAddress'] = workAddress;
      if (gender != null) payload['gender'] = gender;
      if (upiId != null) payload['upiId'] = upiId;
    } else if (workAddress != null) {
      payload['savedAddresses'] = [
        {
          'label': 'Home',
          'addressLine': workAddress,
          if (homeCity != null) 'city': homeCity,
          if (homePincode != null) 'pincode': homePincode,
          'location': {
            'type': 'Point',
            'coordinates': [0, 0],
          },
        },
      ];
    }

    Map<String, dynamic> res;
    try {
      res = await _api.patch('/api/auth/me', data: payload);
    } catch (_) {
      res = await _api.put('/api/users/me', data: payload);
    }

    final userJson = res['user'] ?? res['data'];
    if (res['success'] != true || userJson == null) {
      throw ApiException(res['message']?.toString() ?? 'Profile update failed');
    }
    final user = mapUser(Map<String, dynamic>.from(userJson as Map));
    await _tokens.saveProfile(name: user.name, phone: user.phone);
    return user;
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
    final profileRaw = json['workerProfile'];
    final profile = profileRaw is Map
        ? Map<String, dynamic>.from(profileRaw)
        : <String, dynamic>{};
    final hasProfile = profile.isNotEmpty;

    final emRaw = json['emergencyContact'];
    final em = emRaw is Map
        ? Map<String, dynamic>.from(emRaw)
        : <String, dynamic>{};

    final addrsRaw = json['savedAddresses'];
    Map<String, dynamic>? homeAddr;
    if (addrsRaw is List && addrsRaw.isNotEmpty && addrsRaw.first is Map) {
      homeAddr = Map<String, dynamic>.from(addrsRaw.first as Map);
    }

    final rawCategories = profile['categories'];
    final categories = rawCategories is List
        ? rawCategories.map((e) => e.toString()).toList()
        : <String>[];

    final rawSkills = profile['skills'];
    final skills = rawSkills is List
        ? rawSkills.map((e) => e.toString()).toList()
        : <String>[];

    final upiRaw = profile['upi'];
    final upiId = upiRaw is Map ? upiRaw['upiId']?.toString() : null;

    final rateNum = profile['hourlyRate'] ?? profile['rate'] ?? 0;
    final expNum = profile['experienceYears'] ?? 0;

    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? 'Fixly User',
      phone: (json['phone'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: roleStr == 'worker' ? UserRole.worker : UserRole.customer,
      avatar: json['avatar'] as String?,
      isVerified: json['isVerified'] == true,
      hasWorkerProfile: hasProfile,
      bio: profile['bio'] as String?,
      workAddress: (profile['workAddress'] as String?) ??
          (homeAddr?['addressLine'] as String?),
      category: profile['category'] as String?,
      categories: categories,
      skills: skills,
      hourlyRate: (rateNum as num).toDouble(),
      experienceYears: (expNum as num).toInt(),
      gender: profile['gender'] as String?,
      upiId: upiId,
      emergencyName: em['name'] as String?,
      emergencyPhone: em['phone'] as String?,
      emergencyRelation: em['relation'] as String?,
      homeCity: homeAddr?['city'] as String?,
      homePincode: homeAddr?['pincode'] as String?,
    );
  }
}
