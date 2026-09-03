import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';

part 'job_feed_state.dart';

class JobFeedCubit extends Cubit<JobFeedState> {
  JobFeedCubit({BookingsApiRepository? bookings})
      : _bookings = bookings ?? BookingsApiRepository(),
        super(const JobFeedState());

  final BookingsApiRepository _bookings;

  Future<void> load() async {
    emit(state.copyWith(status: JobFeedStatus.loading, clearError: true));
    try {
      final jobs = await _bookings.workerIncoming();
      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }

  WorkerJob? jobById(String id) {
    try {
      return state.jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> acceptJob(String id) async {
    emit(state.copyWith(status: JobFeedStatus.loading));
    try {
      await _bookings.accept(id);
      final jobs = await _bookings.workerIncoming();
      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }

  Future<void> declineJob(String id) async {
    emit(state.copyWith(status: JobFeedStatus.loading));
    try {
      await _bookings.decline(id);
      final jobs = await _bookings.workerIncoming();
      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }
}
