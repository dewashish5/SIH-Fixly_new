import 'package:equatable/equatable.dart';

enum UserRole { customer, worker }

enum KycReviewStatus { submitted, inReview, approved, rejected }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email = '',
    this.avatar,
    this.eshramUan,
    this.insured = false,
    this.isVerified = false,
    this.hasWorkerProfile = false,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String? avatar;
  final String? eshramUan;
  final bool insured;
  final bool isVerified;
  /// True when API returned a non-empty workerProfile (onboarding submitted).
  final bool hasWorkerProfile;

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        role,
        avatar,
        eshramUan,
        insured,
        isVerified,
        hasWorkerProfile,
      ];
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

class BookingAddOn extends Equatable {
  const BookingAddOn({
    required this.title,
    required this.price,
    this.quantity = 1,
  });

  final String title;
  final double price;
  final int quantity;

  @override
  List<Object?> get props => [title, price, quantity];
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
    this.addOns = const [],
    this.baseServiceFee,
    this.platformFee,
    this.extraPartsTotal,
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
  final List<BookingAddOn> addOns;
  final double? baseServiceFee;
  final double? platformFee;
  final double? extraPartsTotal;

  Booking copyWith({
    BookingStatus? status,
    String? workerId,
    String? workerName,
    double? estimatedPrice,
    List<BookingAddOn>? addOns,
    double? baseServiceFee,
    double? platformFee,
    double? extraPartsTotal,
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
      addOns: addOns ?? this.addOns,
      baseServiceFee: baseServiceFee ?? this.baseServiceFee,
      platformFee: platformFee ?? this.platformFee,
      extraPartsTotal: extraPartsTotal ?? this.extraPartsTotal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        serviceTitle,
        status,
        estimatedPrice,
        workerId,
        addOns,
      ];
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

enum WorkerGender { male, female, other }

extension WorkerGenderX on WorkerGender {
  String get label => switch (this) {
        WorkerGender.male => 'Male',
        WorkerGender.female => 'Female',
        WorkerGender.other => 'Other',
      };
}

class OnboardingFormData extends Equatable {
  static const _unset = Object();

  const OnboardingFormData({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.dateOfBirth,
    this.gender,
    this.aadhaar = '',
    this.pan = '',
    this.aadhaarFrontPath,
    this.aadhaarBackPath,
    this.panFrontPath,
    this.panBackPath,
    this.skills = const [],
    this.categoryRates = const {},
    this.experienceYears = 0,
    this.bio = '',
    this.serviceRadiusKm = 5,
    this.hasEshram = false,
    this.eshramUan = '',
    this.payoutMethod = PayoutMethod.bank,
    this.accountHolderName = '',
    this.bankAccount = '',
    this.ifscCode = '',
    this.upiId = '',
    this.bankVerified = false,
    this.upiVerified = false,
    this.certificateUploaded = false,
    this.certificatePath,
    this.certificateFileName,
    this.selfieVerified = false,
    this.selfieImageUrl,
  });

  final String fullName;
  final String phone;
  final String email;
  final DateTime? dateOfBirth;
  final WorkerGender? gender;
  final String aadhaar;
  final String pan;
  final String? aadhaarFrontPath;
  final String? aadhaarBackPath;
  final String? panFrontPath;
  final String? panBackPath;
  final List<String> skills;
  /// Hourly rate (₹) per skill/category id.
  final Map<String, int> categoryRates;
  final int experienceYears;
  final String bio;
  final double serviceRadiusKm;
  final bool hasEshram;
  final String eshramUan;
  final PayoutMethod payoutMethod;
  final String accountHolderName;
  final String bankAccount;
  final String ifscCode;
  final String upiId;
  final bool bankVerified;
  final bool upiVerified;
  final bool certificateUploaded;
  final String? certificatePath;
  final String? certificateFileName;
  final bool selfieVerified;
  final String? selfieImageUrl;

  bool get hasAadhaarPhotos =>
      (aadhaarFrontPath?.isNotEmpty ?? false) &&
      (aadhaarBackPath?.isNotEmpty ?? false);

  bool get hasPanPhotos =>
      (panFrontPath?.isNotEmpty ?? false) &&
      (panBackPath?.isNotEmpty ?? false);

  /// Primary rate for API `rate` / `hourlyRate` — first selected skill with a rate.
  int get primaryRate {
    for (final skill in skills) {
      final rate = categoryRates[skill];
      if (rate != null && rate > 0) return rate;
    }
    return 0;
  }

  /// API-shaped rows: `{ category, rate }`.
  List<Map<String, dynamic>> get categoryRatesPayload => skills
      .where((id) => (categoryRates[id] ?? 0) > 0)
      .map(
        (id) => {
          'category': id,
          'rate': categoryRates[id],
        },
      )
      .toList();

  OnboardingFormData copyWith({
    String? fullName,
    String? phone,
    String? email,
    Object? dateOfBirth = _unset,
    Object? gender = _unset,
    String? aadhaar,
    String? pan,
    Object? aadhaarFrontPath = _unset,
    Object? aadhaarBackPath = _unset,
    Object? panFrontPath = _unset,
    Object? panBackPath = _unset,
    List<String>? skills,
    Map<String, int>? categoryRates,
    int? experienceYears,
    String? bio,
    double? serviceRadiusKm,
    bool? hasEshram,
    String? eshramUan,
    PayoutMethod? payoutMethod,
    String? accountHolderName,
    String? bankAccount,
    String? ifscCode,
    String? upiId,
    bool? bankVerified,
    bool? upiVerified,
    bool? certificateUploaded,
    Object? certificatePath = _unset,
    Object? certificateFileName = _unset,
    bool? selfieVerified,
    Object? selfieImageUrl = _unset,
  }) {
    return OnboardingFormData(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      gender: identical(gender, _unset) ? this.gender : gender as WorkerGender?,
      aadhaar: aadhaar ?? this.aadhaar,
      pan: pan ?? this.pan,
      aadhaarFrontPath: identical(aadhaarFrontPath, _unset)
          ? this.aadhaarFrontPath
          : aadhaarFrontPath as String?,
      aadhaarBackPath: identical(aadhaarBackPath, _unset)
          ? this.aadhaarBackPath
          : aadhaarBackPath as String?,
      panFrontPath: identical(panFrontPath, _unset)
          ? this.panFrontPath
          : panFrontPath as String?,
      panBackPath: identical(panBackPath, _unset)
          ? this.panBackPath
          : panBackPath as String?,
      skills: skills ?? this.skills,
      categoryRates: categoryRates ?? this.categoryRates,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      hasEshram: hasEshram ?? this.hasEshram,
      eshramUan: eshramUan ?? this.eshramUan,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankAccount: bankAccount ?? this.bankAccount,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      bankVerified: bankVerified ?? this.bankVerified,
      upiVerified: upiVerified ?? this.upiVerified,
      certificateUploaded: certificateUploaded ?? this.certificateUploaded,
      certificatePath: identical(certificatePath, _unset)
          ? this.certificatePath
          : certificatePath as String?,
      certificateFileName: identical(certificateFileName, _unset)
          ? this.certificateFileName
          : certificateFileName as String?,
      selfieVerified: selfieVerified ?? this.selfieVerified,
      selfieImageUrl: identical(selfieImageUrl, _unset)
          ? this.selfieImageUrl
          : selfieImageUrl as String?,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        phone,
        email,
        dateOfBirth,
        gender,
        aadhaar,
        pan,
        aadhaarFrontPath,
        aadhaarBackPath,
        panFrontPath,
        panBackPath,
        skills,
        categoryRates,
        experienceYears,
        bio,
        serviceRadiusKm,
        hasEshram,
        eshramUan,
        payoutMethod,
        accountHolderName,
        bankAccount,
        ifscCode,
        upiId,
        bankVerified,
        upiVerified,
        certificateUploaded,
        certificatePath,
        certificateFileName,
        selfieVerified,
        selfieImageUrl,
      ];
}

enum PayoutMethod { bank, upi }
