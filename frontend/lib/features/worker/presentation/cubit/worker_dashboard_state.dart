part of 'worker_dashboard_cubit.dart';

enum WorkerDashboardStatus { initial, loading, loaded, failure }

class WorkerDashboardState extends Equatable {
  const WorkerDashboardState({
    this.status = WorkerDashboardStatus.initial,
    this.todayEarnings = 0,
    this.completedJobs = 0,
    this.reliabilityScore = 0,
    this.incomingCount = 0,
    this.isAvailable = true,
    this.activeJob,
  });

  final WorkerDashboardStatus status;
  final double todayEarnings;
  final int completedJobs;
  final int reliabilityScore;
  final int incomingCount;
  final bool isAvailable;
  final WorkerJob? activeJob;

  WorkerDashboardState copyWith({
    WorkerDashboardStatus? status,
    double? todayEarnings,
    int? completedJobs,
    int? reliabilityScore,
    int? incomingCount,
    bool? isAvailable,
    WorkerJob? activeJob,
  }) {
    return WorkerDashboardState(
      status: status ?? this.status,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      completedJobs: completedJobs ?? this.completedJobs,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      incomingCount: incomingCount ?? this.incomingCount,
      isAvailable: isAvailable ?? this.isAvailable,
      activeJob: activeJob ?? this.activeJob,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todayEarnings,
        completedJobs,
        reliabilityScore,
        incomingCount,
        isAvailable,
        activeJob,
      ];
}
