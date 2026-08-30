import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'job_feed_state.dart';

class JobFeedCubit extends Cubit<JobFeedState> {
  JobFeedCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const JobFeedState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: JobFeedStatus.loading));
    await _repo.mockDelay();
    emit(
      JobFeedState(
        status: JobFeedStatus.loaded,
        jobs: _repo.jobs,
      ),
    );
  }

  Future<void> acceptJob(String id) async {
    emit(state.copyWith(status: JobFeedStatus.loading));
    await _repo.mockDelay();
    _repo.acceptJob(id);
    emit(
      JobFeedState(
        status: JobFeedStatus.loaded,
        jobs: _repo.jobs,
      ),
    );
  }
}
