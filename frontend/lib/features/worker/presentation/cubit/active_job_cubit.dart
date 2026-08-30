import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'active_job_state.dart';

class ActiveJobCubit extends Cubit<ActiveJobState> {
  ActiveJobCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const ActiveJobState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: ActiveJobStatus.loading));
    await _repo.mockDelay();
    emit(
      ActiveJobState(
        status: ActiveJobStatus.loaded,
        job: _repo.activeJob,
      ),
    );
  }

  Future<void> completeJob() async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading));
    await _repo.mockDelay();
    emit(
      state.copyWith(
        status: ActiveJobStatus.completed,
        job: state.job!.copyWith(status: JobStatus.completed),
      ),
    );
  }
}
