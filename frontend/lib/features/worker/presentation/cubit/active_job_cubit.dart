import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';

part 'active_job_state.dart';

class ActiveJobCubit extends Cubit<ActiveJobState> {
  ActiveJobCubit({BookingsApiRepository? bookings})
      : _bookings = bookings ?? BookingsApiRepository(),
        super(const ActiveJobState());

  final BookingsApiRepository _bookings;

  Future<void> load() async {
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      final jobs = await _bookings.workerActive();
      emit(
        ActiveJobState(
          status: ActiveJobStatus.loaded,
          job: jobs.isEmpty ? null : jobs.first,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  Future<void> completeJob() async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      await _bookings.complete(state.job!.id);
      emit(
        state.copyWith(
          status: ActiveJobStatus.completed,
          job: state.job!.copyWith(status: JobStatus.completed),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }
}
