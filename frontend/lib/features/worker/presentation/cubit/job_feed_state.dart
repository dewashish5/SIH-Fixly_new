part of 'job_feed_cubit.dart';

enum JobFeedStatus { initial, loading, loaded, failure }

class JobFeedState extends Equatable {
  const JobFeedState({
    this.status = JobFeedStatus.initial,
    this.jobs = const [],
    this.error,
  });

  final JobFeedStatus status;
  final List<WorkerJob> jobs;
  final String? error;

  JobFeedState copyWith({
    JobFeedStatus? status,
    List<WorkerJob>? jobs,
    String? error,
    bool clearError = false,
  }) {
    return JobFeedState(
      status: status ?? this.status,
      jobs: jobs ?? this.jobs,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, jobs, error];
}
