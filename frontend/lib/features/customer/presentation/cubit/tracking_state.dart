part of 'tracking_cubit.dart';

enum TrackingPhase { enRoute, nearby, arriving, arrived }

class TrackingState extends Equatable {
  const TrackingState({
    this.progress = 0,
    this.isActive = false,
    this.workerName,
    this.etaMinutes = 12,
    this.phase = TrackingPhase.enRoute,
    this.workerPosition,
    this.customerPosition,
    this.startPosition,
    this.routeCoordinates = const [],
    this.workerHeading,
    this.distanceMeters = 0,
    this.isSocketConnected = false,
    this.serviceTitle,
    this.arrivalOtp,
    this.bookingId,
    this.workerPhone,
    this.workerRating,
    this.workerAvatar,
  });

  final double progress;
  final bool isActive;
  final String? workerName;
  final int etaMinutes;
  final TrackingPhase phase;
  final MapCoordinate? workerPosition;
  final MapCoordinate? customerPosition;
  final MapCoordinate? startPosition;
  final List<MapCoordinate> routeCoordinates;
  final double? workerHeading;
  final double distanceMeters;
  final bool isSocketConnected;
  final String? serviceTitle;
  final String? arrivalOtp;
  final String? bookingId;
  final String? workerPhone;
  final double? workerRating;
  final String? workerAvatar;

  String phaseLabelFor(String locale) {
    final hi = locale == 'hi';
    return switch (phase) {
      TrackingPhase.enRoute => hi ? 'कार्यकर्ता रास्ते में है' : 'Worker en route',
      TrackingPhase.nearby => hi ? 'कार्यकर्ता पास में है' : 'Worker nearby',
      TrackingPhase.arriving => hi ? 'लगभग पहुंच गए' : 'Almost there',
      TrackingPhase.arrived => hi ? 'कार्यकर्ता पहुंच गया' : 'Worker arrived',
    };
  }

  String get phaseLabel => phaseLabelFor('en');

  TrackingState copyWith({
    double? progress,
    bool? isActive,
    String? workerName,
    int? etaMinutes,
    TrackingPhase? phase,
    MapCoordinate? workerPosition,
    MapCoordinate? customerPosition,
    MapCoordinate? startPosition,
    List<MapCoordinate>? routeCoordinates,
    double? workerHeading,
    double? distanceMeters,
    bool? isSocketConnected,
    String? serviceTitle,
    String? arrivalOtp,
    String? bookingId,
    String? workerPhone,
    double? workerRating,
    String? workerAvatar,
  }) {
    return TrackingState(
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      workerName: workerName ?? this.workerName,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      phase: phase ?? this.phase,
      workerPosition: workerPosition ?? this.workerPosition,
      customerPosition: customerPosition ?? this.customerPosition,
      startPosition: startPosition ?? this.startPosition,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      workerHeading: workerHeading ?? this.workerHeading,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      arrivalOtp: arrivalOtp ?? this.arrivalOtp,
      bookingId: bookingId ?? this.bookingId,
      workerPhone: workerPhone ?? this.workerPhone,
      workerRating: workerRating ?? this.workerRating,
      workerAvatar: workerAvatar ?? this.workerAvatar,
    );
  }

  @override
  List<Object?> get props => [
    progress,
    isActive,
    workerName,
    etaMinutes,
    phase,
    workerPosition,
    customerPosition,
    startPosition,
    routeCoordinates,
    workerHeading,
    distanceMeters,
    isSocketConnected,
    serviceTitle,
    arrivalOtp,
    bookingId,
    workerPhone,
    workerRating,
    workerAvatar,
  ];
}

