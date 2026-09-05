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
    this.routeCoordinates = const [],
  });

  final double progress;
  final bool isActive;
  final String? workerName;
  final int etaMinutes;
  final TrackingPhase phase;
  final MapCoordinate? workerPosition;
  final MapCoordinate? customerPosition;
  final List<MapCoordinate> routeCoordinates;

  String phaseLabelFor(String locale) {
    final hi = locale == 'hi';
    return switch (phase) {
      TrackingPhase.enRoute => hi ? 'कार्यकर्ता रास्ते में' : 'Worker en route',
      TrackingPhase.nearby => hi ? 'कार्यकर्ता पास में' : 'Worker nearby',
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
    List<MapCoordinate>? routeCoordinates,
  }) {
    return TrackingState(
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      workerName: workerName ?? this.workerName,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      phase: phase ?? this.phase,
      workerPosition: workerPosition ?? this.workerPosition,
      customerPosition: customerPosition ?? this.customerPosition,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
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
    routeCoordinates,
  ];
}
