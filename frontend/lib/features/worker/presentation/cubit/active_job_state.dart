part of 'active_job_cubit.dart';

enum ActiveJobStatus {
  initial,
  loading,
  loaded,
  inProgress,
  navigating,
  awaitingPayment,
  paymentReceived,
  completed,
  reviewSubmitted,
  failure,
}

class ActiveJobState extends Equatable {
  const ActiveJobState({
    this.status = ActiveJobStatus.initial,
    this.job,
    this.error,
  });

  final ActiveJobStatus status;
  final WorkerJob? job;
  final String? error;

  ActiveJobState copyWith({
    ActiveJobStatus? status,
    WorkerJob? job,
    String? error,
    bool clearError = false,
  }) {
    return ActiveJobState(
      status: status ?? this.status,
      job: job ?? this.job,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, job, error];
}
