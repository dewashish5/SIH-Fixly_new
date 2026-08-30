part of 'tracking_cubit.dart';

enum TrackingPhase { enRoute, nearby, arriving, arrived }

class TrackingState extends Equatable {
  const TrackingState({
    this.progress = 0,
    this.isActive = false,
    this.workerName,
    this.etaMinutes = 12,
    this.phase = TrackingPhase.enRoute,
  });

  final double progress;
  final bool isActive;
  final String? workerName;
  final int etaMinutes;
  final TrackingPhase phase;

  String phaseLabelFor(String locale) {
    final hi = locale == 'hi';
    return switch (phase) {
      TrackingPhase.enRoute =>
        hi ? 'कार्यकर्ता रास्ते में' : 'Worker en route',
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
  }) {
    return TrackingState(
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      workerName: workerName ?? this.workerName,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      phase: phase ?? this.phase,
    );
  }

  @override
  List<Object?> get props =>
      [progress, isActive, workerName, etaMinutes, phase];
}
