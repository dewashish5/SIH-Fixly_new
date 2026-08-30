part of 'job_feed_cubit.dart';

enum JobFeedStatus { initial, loading, loaded, failure }

class JobFeedState extends Equatable {
  const JobFeedState({
    this.status = JobFeedStatus.initial,
    this.jobs = const [],
  });

  final JobFeedStatus status;
  final List<WorkerJob> jobs;

  JobFeedState copyWith({
    JobFeedStatus? status,
    List<WorkerJob>? jobs,
  }) {
    return JobFeedState(
      status: status ?? this.status,
      jobs: jobs ?? this.jobs,
    );
  }

  @override
  List<Object?> get props => [status, jobs];
}
