part of 'job_feed_cubit.dart';

enum JobFeedStatus { initial, loading, loaded, failure }

class JobFeedState extends Equatable {
  const JobFeedState({
    this.status = JobFeedStatus.initial,
    this.jobs = const [],
    this.actingJobId,
    this.error,
  });

  final JobFeedStatus status;
  final List<WorkerJob> jobs;
  final String? actingJobId;
  final String? error;

  List<WorkerJob> get incomingJobs =>
      jobs.where((j) => j.status == JobStatus.incoming).toList();

  List<WorkerJob> get activeJobs =>
      jobs.where((j) => j.status == JobStatus.active).toList();

  List<WorkerJob> get completedJobs =>
      jobs.where((j) => j.status == JobStatus.completed).toList();

  JobFeedState copyWith({
    JobFeedStatus? status,
    List<WorkerJob>? jobs,
    String? actingJobId,
    bool clearActingJobId = false,
    String? error,
    bool clearError = false,
  }) {
    return JobFeedState(
      status: status ?? this.status,
      jobs: jobs ?? this.jobs,
      actingJobId: clearActingJobId ? null : (actingJobId ?? this.actingJobId),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, jobs, actingJobId, error];
}
