import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/location/app_location.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/models.dart';

class PriceEstimate {
  const PriceEstimate({
    required this.laborMin,
    required this.laborMax,
    required this.materialsMin,
    required this.materialsMax,
    required this.serviceFee,
    required this.minTotal,
    required this.maxTotal,
  });

  final double laborMin;
  final double laborMax;
  final double materialsMin;
  final double materialsMax;
  final double serviceFee;
  final double minTotal;
  final double maxTotal;
}

class BookingsApiRepository {
  BookingsApiRepository({ApiClient? client})
      : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<PriceEstimate> estimate({
    required String serviceId,
    double estimatedHours = 1,
  }) async {
    final res = await _api.post(ApiEndpoints.bookingEstimate, data: {
      'serviceId': serviceId,
      'estimatedHours': estimatedHours,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Estimate failed');
    }
    final est = res['estimate'] as Map<String, dynamic>? ?? {};
    final labor = est['laborEstimate'] as Map<String, dynamic>? ?? {};
    final materials = est['materialsParts'] as Map<String, dynamic>? ?? {};
    final total = est['totalEstimate'] as Map<String, dynamic>? ?? {};
    return PriceEstimate(
      laborMin: (labor['min'] as num?)?.toDouble() ?? 0,
      laborMax: (labor['max'] as num?)?.toDouble() ?? 0,
      materialsMin: (materials['min'] as num?)?.toDouble() ?? 0,
      materialsMax: (materials['max'] as num?)?.toDouble() ?? 0,
      serviceFee: (est['serviceFee'] as num?)?.toDouble() ?? 0,
      minTotal: (total['min'] as num?)?.toDouble() ?? 0,
      maxTotal: (total['max'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<Booking> create({
    required String serviceId,
    required String addressLine,
    String? problemDescription,
    String? workerId,
    DateTime? scheduledTime,
    double? lng,
    double? lat,
    String serviceTitle = 'Service',
    List<String> photoPaths = const [],
  }) async {
    final loc = AppLocation.instance;
    final useLng = lng ?? (loc.hasFix ? loc.requireLng : null);
    final useLat = lat ?? (loc.hasFix ? loc.requireLat : null);
    if (useLng == null || useLat == null) {
      throw ApiException('Location required to create booking');
    }

    final Object data;
    if (photoPaths.isEmpty) {
      data = {
        'serviceId': serviceId,
        'workerId': ?workerId,
        'problemDescription': ?problemDescription,
        'addressLine': addressLine,
        'coordinates': [useLng, useLat],
        'scheduledTime': ?scheduledTime?.toUtc().toIso8601String(),
      };
    } else {
      final map = <String, dynamic>{
        'serviceId': serviceId,
        if (workerId != null) 'workerId': workerId,
        if (problemDescription != null) 'problemDescription': problemDescription,
        'addressLine': addressLine,
        'coordinates': jsonEncode([useLng, useLat]),
        if (scheduledTime != null)
          'scheduledTime': scheduledTime.toUtc().toIso8601String(),
      };
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
      map['photos'] = files;
      data = FormData.fromMap(map);
    }

    final res = await _api.post(ApiEndpoints.createBooking, data: data);
    if (res['success'] != true || res['booking'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Booking failed');
    }
    return mapBooking(
      Map<String, dynamic>.from(res['booking'] as Map),
      serviceTitleFallback: serviceTitle,
    );
  }

  Future<Booking> getById(String bookingId, {String serviceTitle = 'Service'}) async {
    final res = await _api.get(ApiEndpoints.bookingById(bookingId));
    if (res['success'] != true || res['booking'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Booking not found');
    }
    return mapBooking(
      Map<String, dynamic>.from(res['booking'] as Map),
      serviceTitleFallback: serviceTitle,
    );
  }

  Future<Booking> cancel(String bookingId, {String serviceTitle = 'Service'}) async {
    final res = await _api.patch(ApiEndpoints.cancelBooking(bookingId));
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Cancel failed');
    }
    final booking = res['booking'];
    if (booking is Map) {
      return mapBooking(
        Map<String, dynamic>.from(booking),
        serviceTitleFallback: serviceTitle,
      );
    }
    return getById(bookingId, serviceTitle: serviceTitle);
  }

  Future<Booking> verifyArrivalOtp({
    required String bookingId,
    required String otp,
    String serviceTitle = 'Service',
  }) async {
    final res = await _api.post(ApiEndpoints.verifyArrivalOtp(bookingId), data: {
      'otp': otp,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'OTP failed');
    }
    final booking = res['booking'];
    if (booking is Map) {
      return mapBooking(
        Map<String, dynamic>.from(booking),
        serviceTitleFallback: serviceTitle,
      );
    }
    return getById(bookingId, serviceTitle: serviceTitle);
  }

  Future<void> complete(String bookingId) async {
    final res = await _api.post(ApiEndpoints.completeBooking(bookingId));
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Complete failed');
    }
  }

  Future<void> addParts({
    required String bookingId,
    required List<Map<String, dynamic>> extraItems,
  }) async {
    final res = await _api.patch(ApiEndpoints.addParts(bookingId), data: {
      'extraItems': extraItems,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Add parts failed');
    }
  }

  Future<List<Booking>> history() async {
    try {
      final res = await _api.get(ApiEndpoints.bookingHistory);
      final data = res['data'] ?? res['bookings'];
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => mapBooking(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<WorkerJob> workerJobById(String bookingId) async {
    final res = await _api.get(ApiEndpoints.bookingById(bookingId));
    if (res['success'] != true || res['booking'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Job not found');
    }
    return mapWorkerJob(Map<String, dynamic>.from(res['booking'] as Map));
  }

  Future<List<WorkerJob>> workerIncoming() =>
      _workerJobs(ApiEndpoints.workerIncomingJobs, JobStatus.incoming);

  Future<List<WorkerJob>> workerActive() =>
      _workerJobs(ApiEndpoints.workerActiveJobs, JobStatus.active);

  Future<List<WorkerJob>> workerCompleted() =>
      _workerJobs(ApiEndpoints.workerCompletedJobs, JobStatus.completed);

  Future<List<WorkerJob>> _workerJobs(String path, JobStatus status) async {
    final res = await _api.get(path);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Jobs failed');
    }
    final data = res['data'] ?? res['bookings'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => mapWorkerJob(Map<String, dynamic>.from(e), fallbackStatus: status))
        .toList();
  }

  Future<void> accept(String bookingId) async {
    final res = await _api.post(ApiEndpoints.acceptJob(bookingId));
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Accept failed');
    }
  }

  Future<void> decline(String bookingId, {String reason = 'OTHER'}) async {
    final res = await _api.post(ApiEndpoints.declineJob(bookingId), data: {
      'reason': reason,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Decline failed');
    }
  }

  Future<void> startJob(String bookingId) async {
    final res = await _api.post(ApiEndpoints.startJob(bookingId));
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Start failed');
    }
  }

  static WorkerJob mapWorkerJob(
    Map<String, dynamic> json, {
    JobStatus fallbackStatus = JobStatus.incoming,
  }) {
    final booking = mapBooking(json);
    final customer = json['customer'];
    var customerName = 'Customer';
    if (customer is Map) {
      customerName = (customer['name'] as String?) ?? customerName;
    }
    final statusRaw = (json['status'] ?? '').toString().toUpperCase();
    final status = switch (statusRaw) {
      'SEARCHING' => JobStatus.incoming,
      'COMPLETED' => JobStatus.completed,
      'CANCELLED' => JobStatus.completed,
      _ => JobStatus.active,
    };
    return WorkerJob(
      id: booking.id,
      title: booking.serviceTitle,
      customerName: customerName,
      address: booking.address ?? '',
      pay: booking.estimatedPrice,
      status: status == JobStatus.incoming ? fallbackStatus : status,
      distanceKm: 0,
    );
  }

  static Booking mapBooking(
    Map<String, dynamic> json, {
    String serviceTitleFallback = 'Service',
  }) {
    final service = json['service'];
    String serviceId;
    String serviceTitle = serviceTitleFallback;
    if (service is Map) {
      serviceId = (service['_id'] ?? service['id'] ?? '').toString();
      serviceTitle = (service['title'] as String?) ?? serviceTitleFallback;
    } else {
      serviceId = service?.toString() ?? '';
    }

    final worker = json['worker'];
    String? workerId;
    String? workerName;
    if (worker is Map) {
      workerId = (worker['_id'] ?? worker['id'])?.toString();
      workerName = worker['name'] as String?;
    } else if (worker != null) {
      workerId = worker.toString();
    }

    final address = json['serviceAddress'];
    String? addressLine;
    if (address is Map) {
      addressLine = address['addressLine'] as String?;
    }

    final invoice = json['invoice'];
    double price = 0;
    double? baseServiceFee;
    double? platformFee;
    double? extraPartsTotal;
    if (invoice is Map) {
      baseServiceFee = (invoice['baseServiceFee'] as num?)?.toDouble();
      platformFee = (invoice['platformFee'] as num?)?.toDouble();
      extraPartsTotal = (invoice['extraPartsTotal'] as num?)?.toDouble();
      price = (invoice['totalAmount'] as num?)?.toDouble() ??
          (invoice['baseServiceFee'] as num?)?.toDouble() ??
          0;
    }

    final addOnsRaw = json['addOns'];
    final addOns = <BookingAddOn>[];
    if (addOnsRaw is List) {
      for (final item in addOnsRaw) {
        if (item is! Map) continue;
        addOns.add(
          BookingAddOn(
            title: (item['title'] as String?) ?? 'Part',
            price: (item['price'] as num?)?.toDouble() ?? 0,
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          ),
        );
      }
    }

    final scheduled = json['scheduledTime'];
    DateTime? scheduledAt;
    if (scheduled is String) {
      scheduledAt = DateTime.tryParse(scheduled);
    }

    return Booking(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      status: mapStatus(json['status']?.toString()),
      estimatedPrice: price,
      workerId: workerId,
      workerName: workerName,
      address: addressLine,
      scheduledAt: scheduledAt,
      addOns: addOns,
      baseServiceFee: baseServiceFee,
      platformFee: platformFee,
      extraPartsTotal: extraPartsTotal,
    );
  }

  static BookingStatus mapStatus(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'SEARCHING':
        return BookingStatus.searching;
      case 'ASSIGNED':
      case 'ACCEPTED':
      case 'EN_ROUTE':
      case 'ARRIVED':
        return BookingStatus.accepted;
      case 'IN_PROGRESS':
      case 'STARTED':
        return BookingStatus.inProgress;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'PAID':
        return BookingStatus.paid;
      default:
        return BookingStatus.draft;
    }
  }
}
