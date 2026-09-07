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
    this.bio,
    this.workAddress,
    this.category,
    this.categories = const [],
    this.skills = const [],
    this.hourlyRate = 0,
    this.experienceYears = 0,
    this.gender,
    this.upiId,
    this.emergencyName,
    this.emergencyPhone,
    this.emergencyRelation,
    this.homeCity,
    this.homePincode,
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
  final String? bio;
  final String? workAddress;
  final String? category;
  final List<String> categories;
  final List<String> skills;
  final double hourlyRate;
  final int experienceYears;
  final String? gender;
  final String? upiId;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? emergencyRelation;
  final String? homeCity;
  final String? homePincode;

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
    bio,
    workAddress,
    category,
    categories,
    skills,
    hourlyRate,
    experienceYears,
    gender,
    upiId,
    emergencyName,
    emergencyPhone,
    emergencyRelation,
    homeCity,
    homePincode,
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
    this.category,
    this.categories = const [],
    this.title,
    this.hourlyRate,
    this.minimumCharge,
    this.rateFormatted,
    this.distanceKm,
    this.distanceFormatted,
    this.isOnline = false,
    this.isAvailable = false,
    this.reviewCount = 0,
    this.reviews = const [],
    this.onTimeArrival,
    this.completionRate,
    this.customerFeedback,
    this.cancellationRate,
    this.serviceRadiusKm,
    this.kycStatus,
    this.isEmailVerified = false,
    this.bio,
    this.experienceYears,
    this.isVerified = true,
  });

  final String id;
  final String name;
  final List<String> skills;
  final double rating;
  final int jobsCompleted;
  final int reliabilityScore;
  final String? avatarUrl;
  final bool insured;
  final String? category;
  final List<String> categories;
  final String? title;
  final double? hourlyRate;
  final double? minimumCharge;
  final String? rateFormatted;
  final double? distanceKm;
  final String? distanceFormatted;
  final bool isOnline;
  final bool isAvailable;
  final int reviewCount;
  final List<WorkerReview> reviews;
  final double? onTimeArrival;
  final double? completionRate;
  final double? customerFeedback;
  final double? cancellationRate;
  final double? serviceRadiusKm;
  final String? kycStatus;
  final bool isEmailVerified;
  final String? bio;
  final int? experienceYears;
  final bool isVerified;

  @override
  List<Object?> get props => [
    id,
    name,
    skills,
    rating,
    jobsCompleted,
    reliabilityScore,
    insured,
    category,
    categories,
    title,
    hourlyRate,
    minimumCharge,
    rateFormatted,
    distanceKm,
    distanceFormatted,
    isOnline,
    isAvailable,
    reviewCount,
    reviews,
    onTimeArrival,
    completionRate,
    customerFeedback,
    cancellationRate,
    serviceRadiusKm,
    kycStatus,
    isEmailVerified,
    bio,
    experienceYears,
    isVerified,
  ];
}

class WorkerReview extends Equatable {
  const WorkerReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [reviewerName, rating, comment, createdAt];
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
    this.imageUrl,
    this.estimatedTime,
    this.whatsIncluded = const [],
    this.isActive = true,
  });

  final String id;
  final String categoryId;
  final String title;
  final String? titleHi;
  final String description;
  final String? descriptionHi;
  final double priceFrom;
  final double rating;
  final String? imageUrl;
  final String? estimatedTime;
  final List<String> whatsIncluded;
  final bool isActive;

  String titleFor(String locale) =>
      locale == 'hi' && titleHi != null ? titleHi! : title;

  String descriptionFor(String locale) =>
      locale == 'hi' && descriptionHi != null ? descriptionHi! : description;

  @override
  List<Object?> get props => [
    id,
    categoryId,
    title,
    priceFrom,
    rating,
    imageUrl,
    estimatedTime,
    whatsIncluded,
    isActive,
  ];
}

enum BookingStatus {
  draft,
  searching,
  accepted,
  arrived,
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

class BookingInvoice extends Equatable {
  const BookingInvoice({
    required this.bookingId,
    required this.serviceName,
    required this.status,
    required this.baseServiceFee,
    required this.extraPartsTotal,
    required this.platformFee,
    required this.totalAmount,
    this.paymentStatus,
    this.paymentMethod,
    this.transactionId,
    this.customerName,
    this.customerPhone,
    this.workerName,
    this.workerPhone,
    this.addOns = const [],
    this.jobStartedAt,
    this.jobCompletedAt,
  });

  final String bookingId;
  final String serviceName;
  final String status;
  final double baseServiceFee;
  final double extraPartsTotal;
  final double platformFee;
  final double totalAmount;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? transactionId;
  final String? customerName;
  final String? customerPhone;
  final String? workerName;
  final String? workerPhone;
  final List<BookingAddOn> addOns;
  final DateTime? jobStartedAt;
  final DateTime? jobCompletedAt;

  factory BookingInvoice.fromJson(Map<String, dynamic> json) {
    return BookingInvoice(
      bookingId: json['bookingId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? 'Service',
      status: json['status']?.toString() ?? 'PENDING',
      baseServiceFee: (json['baseServiceFee'] as num?)?.toDouble() ?? 0,
      extraPartsTotal: (json['extraPartsTotal'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      workerName: json['workerName']?.toString(),
      workerPhone: json['workerPhone']?.toString(),
      addOns: (json['addOns'] as List?)
              ?.map((e) => BookingAddOn(
                    title: e['title']?.toString() ?? '',
                    price: (e['price'] as num?)?.toDouble() ?? 0,
                    quantity: (e['quantity'] as num?)?.toInt() ?? 1,
                  ))
              .toList() ??
          const [],
      jobStartedAt: json['jobStartedAt'] != null ? DateTime.tryParse(json['jobStartedAt'].toString()) : null,
      jobCompletedAt: json['jobCompletedAt'] != null ? DateTime.tryParse(json['jobCompletedAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [bookingId, totalAmount, paymentStatus, addOns];
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
    this.displayId,
    this.serviceCategory,
    this.serviceImage,
    this.estimatedTime,
    this.whatsIncluded = const [],
    this.problemDescription,
    this.problemPhotos = const [],
    this.problemVideos = const [],
    this.paymentMethod,
    this.paymentStatus,
    this.transactionId,
    this.arrivalOtp,
    this.createdAt,
    this.jobStartedAt,
    this.jobCompletedAt,
    this.isReviewed = false,
    this.workerAvatar,
    this.customerName,
    this.customerPhone,
    this.customerLat,
    this.customerLng,
    this.rawStatus,
    this.bookingType,
    this.isEmergency = false,
    this.urgentFee,
    this.timeSlot,
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
  final String? displayId;
  final String? serviceCategory;
  final String? serviceImage;
  final String? estimatedTime;
  final List<String> whatsIncluded;
  final String? problemDescription;
  final List<String> problemPhotos;
  final List<String> problemVideos;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? transactionId;
  final String? arrivalOtp;
  final DateTime? createdAt;
  final DateTime? jobStartedAt;
  final DateTime? jobCompletedAt;
  final bool isReviewed;
  final String? workerAvatar;
  final String? customerName;
  final String? customerPhone;
  final double? customerLat;
  final double? customerLng;
  final String? rawStatus;
  final String? bookingType;
  final bool isEmergency;
  final double? urgentFee;
  final String? timeSlot;

  double get totalPrice {
    final base = baseServiceFee ?? estimatedPrice;
    final extra = extraPartsTotal ?? 0.0;
    final platform = platformFee ?? 0.0;
    final addOnsTotal = addOns.fold<double>(0.0, (sum, a) => sum + (a.price * a.quantity));
    final calculated = base + extra + platform + addOnsTotal;
    return calculated > 0 ? calculated : estimatedPrice;
  }

  Booking copyWith({
    BookingStatus? status,
    String? workerId,
    String? workerName,
    double? estimatedPrice,
    List<BookingAddOn>? addOns,
    double? baseServiceFee,
    double? platformFee,
    double? extraPartsTotal,
    String? rawStatus,
    String? paymentStatus,
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
      displayId: displayId,
      serviceCategory: serviceCategory,
      serviceImage: serviceImage,
      estimatedTime: estimatedTime,
      whatsIncluded: whatsIncluded,
      problemDescription: problemDescription,
      problemPhotos: problemPhotos,
      problemVideos: problemVideos,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId,
      arrivalOtp: arrivalOtp,
      createdAt: createdAt,
      jobStartedAt: jobStartedAt,
      jobCompletedAt: jobCompletedAt,
      isReviewed: isReviewed,
      workerAvatar: workerAvatar,
      customerName: customerName,
      customerPhone: customerPhone,
      customerLat: customerLat,
      customerLng: customerLng,
      rawStatus: rawStatus ?? this.rawStatus,
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
    displayId,
    problemDescription,
    paymentStatus,
    createdAt,
    customerName,
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
    this.customerLat,
    this.customerLng,
    this.customerPhone,
    this.customerAvatar,
    this.problemDescription,
    this.problemPhotos = const [],
    this.serviceCategory,
    this.serviceImage,
    this.arrivalOtp,
    this.baseServiceFee,
    this.platformFee,
    this.extraPartsTotal,
    this.addOns = const [],
    this.jobStartedAt,
    this.jobCompletedAt,
    this.rawStatus,
    this.invoice,
  });

  final String id;
  final String title;
  final String customerName;
  final String address;
  final double pay;
  final JobStatus status;
  final double distanceKm;
  final double? customerLat;
  final double? customerLng;
  final String? customerPhone;
  final String? customerAvatar;
  final String? problemDescription;
  final List<String> problemPhotos;
  final String? serviceCategory;
  final String? serviceImage;
  final String? arrivalOtp;
  final double? baseServiceFee;
  final double? platformFee;
  final double? extraPartsTotal;
  final List<BookingAddOn> addOns;
  final DateTime? jobStartedAt;
  final DateTime? jobCompletedAt;

  /// Raw backend status string e.g. 'APPROVED', 'ARRIVED', 'IN_PROGRESS'
  final String? rawStatus;
  final BookingInvoice? invoice;

  String get bookingId => id;

  WorkerJob copyWith({
    JobStatus? status,
    String? rawStatus,
    List<BookingAddOn>? addOns,
    double? extraPartsTotal,
    DateTime? jobStartedAt,
    DateTime? jobCompletedAt,
    BookingInvoice? invoice,
  }) {
    return WorkerJob(
      id: id,
      title: title,
      customerName: customerName,
      address: address,
      pay: pay,
      status: status ?? this.status,
      distanceKm: distanceKm,
      customerLat: customerLat,
      customerLng: customerLng,
      customerPhone: customerPhone,
      customerAvatar: customerAvatar,
      problemDescription: problemDescription,
      problemPhotos: problemPhotos,
      serviceCategory: serviceCategory,
      serviceImage: serviceImage,
      arrivalOtp: arrivalOtp,
      baseServiceFee: baseServiceFee,
      platformFee: platformFee,
      extraPartsTotal: extraPartsTotal ?? this.extraPartsTotal,
      addOns: addOns ?? this.addOns,
      jobStartedAt: jobStartedAt ?? this.jobStartedAt,
      jobCompletedAt: jobCompletedAt ?? this.jobCompletedAt,
      rawStatus: rawStatus ?? this.rawStatus,
      invoice: invoice ?? this.invoice,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    pay,
    status,
    rawStatus,
    customerLat,
    customerLng,
    addOns,
  ];
}

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.label,
    required this.amount,
    required this.isCredit,
    this.date,
    this.transactionId,
  });

  final String id;
  final String label;
  final double amount;
  final bool isCredit;
  final DateTime? date;
  final String? transactionId;

  @override
  List<Object?> get props => [id, label, amount, isCredit, date, transactionId];
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.category,
    this.eventType,
    this.entityType,
    this.entityId,
    this.bookingId,
    this.action,
    this.data = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] ?? json['time'];
    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: (json['body'] ?? json['message'])?.toString() ?? '',
      time: DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now(),
      read: json['isRead'] == true || json['read'] == true,
      category: json['category']?.toString(),
      eventType: json['eventType']?.toString(),
      entityType: json['entityType']?.toString(),
      entityId: json['entityId']?.toString(),
      bookingId: json['bookingId']?.toString(),
      action:
          (json['action'] ??
                  (json['data'] is Map ? json['data']['action'] : null))
              ?.toString(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final String? category;
  final String? eventType;
  final String? entityType;
  final String? entityId;
  final String? bookingId;
  final String? action;
  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    time,
    read,
    category,
    eventType,
    entityType,
    entityId,
    bookingId,
    action,
    data,
  ];
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
      (panFrontPath?.isNotEmpty ?? false) && (panBackPath?.isNotEmpty ?? false);

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
      .map((id) => {'category': id, 'rate': categoryRates[id]})
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

class CouponBanner extends Equatable {
  const CouponBanner({
    required this.id,
    required this.title,
    required this.code,
    required this.discount,
    this.description = '',
    this.imageUrl = '',
    this.gradientColors = const ['#1E3A8A', '#3B82F6'],
    this.category = 'all',
    this.targetUserRole = 'all',
    this.minOrderValue = 0,
    this.maxDiscount = 500,
    this.validUntil,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String code;
  final String discount;
  final String description;
  final String imageUrl;
  final List<String> gradientColors;
  final String category;
  final String targetUserRole;
  final double minOrderValue;
  final double maxDiscount;
  final DateTime? validUntil;
  final bool isActive;

  factory CouponBanner.fromJson(Map<String, dynamic> json) {
    return CouponBanner(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discount: json['discount']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      gradientColors: (json['gradient'] as List?)?.map((e) => e.toString()).toList() ??
          const ['#1E3A8A', '#3B82F6'],
      category: json['category']?.toString() ?? 'all',
      targetUserRole: json['targetUserRole']?.toString() ?? 'all',
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 500,
      validUntil: json['validUntil'] != null
          ? DateTime.tryParse(json['validUntil'].toString())
          : null,
      isActive: json['isActive'] != false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        code,
        discount,
        description,
        imageUrl,
        gradientColors,
        category,
        validUntil,
        isActive,
      ];
}
