part of 'worker_dashboard_cubit.dart';

enum WorkerDashboardStatus { initial, loading, loaded, failure }

class WorkerDashboardState extends Equatable {
  const WorkerDashboardState({
    this.status = WorkerDashboardStatus.initial,
    this.workerName = '',
    this.todayEarnings = 0,
    this.completedJobs = 0,
    this.reliabilityScore = 0,
    this.incomingCount = 0,
    this.incomingJobs = const [],
    this.isAvailable = false,
    this.activeJob,
    this.acceptingJobId,
    this.welfareFund = 0,
    this.error,
  });

  final WorkerDashboardStatus status;
  final String workerName;
  final double todayEarnings;
  final int completedJobs;
  final int reliabilityScore;
  final int incomingCount;
  final List<WorkerJob> incomingJobs;
  final bool isAvailable;
  final WorkerJob? activeJob;
  final String? acceptingJobId;
  final double welfareFund;
  final String? error;

  WorkerDashboardState copyWith({
    WorkerDashboardStatus? status,
    String? workerName,
    double? todayEarnings,
    int? completedJobs,
    int? reliabilityScore,
    int? incomingCount,
    List<WorkerJob>? incomingJobs,
    bool? isAvailable,
    WorkerJob? activeJob,
    String? acceptingJobId,
    bool clearAcceptingJobId = false,
    double? welfareFund,
    String? error,
    bool clearError = false,
  }) {
    return WorkerDashboardState(
      status: status ?? this.status,
      workerName: workerName ?? this.workerName,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      completedJobs: completedJobs ?? this.completedJobs,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      incomingCount: incomingCount ?? this.incomingCount,
      incomingJobs: incomingJobs ?? this.incomingJobs,
      isAvailable: isAvailable ?? this.isAvailable,
      activeJob: activeJob ?? this.activeJob,
      acceptingJobId: clearAcceptingJobId ? null : (acceptingJobId ?? this.acceptingJobId),
      welfareFund: welfareFund ?? this.welfareFund,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        workerName,
        todayEarnings,
        completedJobs,
        reliabilityScore,
        incomingCount,
        incomingJobs,
        isAvailable,
        activeJob,
        acceptingJobId,
        welfareFund,
        error,
      ];
}
