import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/worker_realtime_service.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';

part 'job_feed_state.dart';

class JobFeedCubit extends Cubit<JobFeedState> {
  JobFeedCubit({BookingsApiRepository? bookings})
    : _bookings = bookings ?? BookingsApiRepository(),
      super(const JobFeedState());

  final BookingsApiRepository _bookings;
  StreamSubscription? _incomingSub;
  StreamSubscription? _claimedSub;

  Future<void> load() async {
    emit(state.copyWith(status: JobFeedStatus.loading, clearError: true));
    try {
      final results = await Future.wait([
        _bookings.workerIncoming(),
        _bookings.workerActive(),
        _bookings.workerCompleted(),
      ]);
      final jobs = <WorkerJob>[...results[0], ...results[1], ...results[2]];

      _incomingSub ??= WorkerRealtimeService.instance.incomingJobsStream.listen((_) {
        _silentReload();
      });
      _claimedSub ??= WorkerRealtimeService.instance.jobClaimedStream.listen((_) {
        _silentReload();
      });

      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }

  Future<void> _silentReload() async {
    try {
      if (isClosed) return;
      final jobs = await _loadAllJobs();
      if (!isClosed) {
        emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
      }
    } catch (_) {}
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
      await AppPreferences.instance.setActiveWorkerJobId(id);
      final jobs = await _loadAllJobs();
      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }

  Future<void> declineJob(String id) async {
    emit(state.copyWith(status: JobFeedStatus.loading));
    try {
      await _bookings.decline(id);
      final jobs = await _loadAllJobs();
      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }

  Future<void> cancelScheduledJob(String id) async {
    emit(state.copyWith(status: JobFeedStatus.loading));
    try {
      await _bookings.workerCancel(id);
      final jobs = await _loadAllJobs();
      emit(JobFeedState(status: JobFeedStatus.loaded, jobs: jobs));
    } on ApiException catch (e) {
      emit(state.copyWith(status: JobFeedStatus.failure, error: e.message));
    }
  }

  Future<List<WorkerJob>> _loadAllJobs() async {
    final results = await Future.wait([
      _bookings.workerIncoming(),
      _bookings.workerActive(),
      _bookings.workerCompleted(),
    ]);
    return <WorkerJob>[...results[0], ...results[1], ...results[2]];
  }

  @override
  Future<void> close() {
    _incomingSub?.cancel();
    _claimedSub?.cancel();
    return super.close();
  }
}
