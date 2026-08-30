import 'package:equatable/equatable.dart';

enum UserRole { customer, worker }

enum KycReviewStatus { submitted, inReview, approved }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.eshramUan,
    this.insured = false,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? eshramUan;
  final bool insured;

  @override
  List<Object?> get props => [id, name, phone, role, eshramUan, insured];
}

class WorkerProfile extends Equatable {
  const WorkerProfile({
    required this.id,
    required this.name,
    required this.skills,
    required this.rating,
    required this.jobsCompleted,
    required this.reliabilityScore,
    this.avatarUrl,
    this.insured = false,
  });

  final String id;
  final String name;
  final List<String> skills;
  final double rating;
  final int jobsCompleted;
  final int reliabilityScore;
  final String? avatarUrl;
  final bool insured;

  @override
  List<Object?> get props =>
      [id, name, skills, rating, jobsCompleted, reliabilityScore, insured];
}

class ServiceItem extends Equatable {
  const ServiceItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.priceFrom,
    required this.rating,
    this.titleHi,
    this.descriptionHi,
  });

  final String id;
  final String categoryId;
  final String title;
  final String? titleHi;
  final String description;
  final String? descriptionHi;
  final double priceFrom;
  final double rating;

  String titleFor(String locale) =>
      locale == 'hi' && titleHi != null ? titleHi! : title;

  String descriptionFor(String locale) =>
      locale == 'hi' && descriptionHi != null ? descriptionHi! : description;

  @override
  List<Object?> get props => [id, categoryId, title, priceFrom, rating];
}

enum BookingStatus {
  draft,
  searching,
  accepted,
  inProgress,
  completed,
  paid,
}

class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.status,
    required this.estimatedPrice,
    this.workerId,
    this.workerName,
    this.address,
    this.scheduledAt,
  });

  final String id;
  final String serviceId;
  final String serviceTitle;
  final BookingStatus status;
  final double estimatedPrice;
  final String? workerId;
  final String? workerName;
  final String? address;
  final DateTime? scheduledAt;

  Booking copyWith({
    BookingStatus? status,
    String? workerId,
    String? workerName,
    double? estimatedPrice,
  }) {
    return Booking(
      id: id,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      status: status ?? this.status,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      address: address,
      scheduledAt: scheduledAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, serviceId, serviceTitle, status, estimatedPrice, workerId];
}

enum JobStatus { incoming, active, completed }

class WorkerJob extends Equatable {
  const WorkerJob({
    required this.id,
    required this.title,
    required this.customerName,
    required this.address,
    required this.pay,
    required this.status,
    required this.distanceKm,
  });

  final String id;
  final String title;
  final String customerName;
  final String address;
  final double pay;
  final JobStatus status;
  final double distanceKm;

  WorkerJob copyWith({JobStatus? status}) {
    return WorkerJob(
      id: id,
      title: title,
      customerName: customerName,
      address: address,
      pay: pay,
      status: status ?? this.status,
      distanceKm: distanceKm,
    );
  }

  @override
  List<Object?> get props => [id, title, pay, status];
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  @override
  List<Object?> get props => [id, title, body, time, read];
}

class OnboardingFormData extends Equatable {
  static const _unset = Object();

  const OnboardingFormData({
    this.fullName = '',
    this.aadhaar = '',
    this.pan = '',
    this.skills = const [],
    this.serviceRadiusKm = 5,
    this.hasEshram = false,
    this.eshramUan = '',
    this.bankAccount = '',
    this.upiId = '',
    this.certificateUploaded = false,
    this.selfieVerified = false,
    this.selfieImageUrl,
  });

  final String fullName;
  final String aadhaar;
  final String pan;
  final List<String> skills;
  final double serviceRadiusKm;
  final bool hasEshram;
  final String eshramUan;
  final String bankAccount;
  final String upiId;
  final bool certificateUploaded;
  final bool selfieVerified;
  final String? selfieImageUrl;

  OnboardingFormData copyWith({
    String? fullName,
    String? aadhaar,
    String? pan,
    List<String>? skills,
    double? serviceRadiusKm,
    bool? hasEshram,
    String? eshramUan,
    String? bankAccount,
    String? upiId,
    bool? certificateUploaded,
    bool? selfieVerified,
    Object? selfieImageUrl = _unset,
  }) {
    return OnboardingFormData(
      fullName: fullName ?? this.fullName,
      aadhaar: aadhaar ?? this.aadhaar,
      pan: pan ?? this.pan,
      skills: skills ?? this.skills,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      hasEshram: hasEshram ?? this.hasEshram,
      eshramUan: eshramUan ?? this.eshramUan,
      bankAccount: bankAccount ?? this.bankAccount,
      upiId: upiId ?? this.upiId,
      certificateUploaded: certificateUploaded ?? this.certificateUploaded,
      selfieVerified: selfieVerified ?? this.selfieVerified,
      selfieImageUrl: identical(selfieImageUrl, _unset)
          ? this.selfieImageUrl
          : selfieImageUrl as String?,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        aadhaar,
        pan,
        skills,
        serviceRadiusKm,
        hasEshram,
        eshramUan,
        bankAccount,
        upiId,
        certificateUploaded,
        selfieVerified,
        selfieImageUrl,
      ];
}
