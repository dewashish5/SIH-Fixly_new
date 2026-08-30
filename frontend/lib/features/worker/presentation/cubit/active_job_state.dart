part of 'active_job_cubit.dart';

enum ActiveJobStatus { initial, loading, loaded, completed, failure }

class ActiveJobState extends Equatable {
  const ActiveJobState({
    this.status = ActiveJobStatus.initial,
    this.job,
  });

  final ActiveJobStatus status;
  final WorkerJob? job;

  ActiveJobState copyWith({
    ActiveJobStatus? status,
    WorkerJob? job,
  }) {
    return ActiveJobState(
      status: status ?? this.status,
      job: job ?? this.job,
    );
  }

  @override
  List<Object?> get props => [status, job];
}
