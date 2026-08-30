import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'worker_dashboard_state.dart';

class WorkerDashboardCubit extends Cubit<WorkerDashboardState> {
  WorkerDashboardCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const WorkerDashboardState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: WorkerDashboardStatus.loading));
    await _repo.mockDelay();
    emit(
      WorkerDashboardState(
        status: WorkerDashboardStatus.loaded,
        todayEarnings: _repo.todayEarnings,
        completedJobs: _repo.completedJobs,
        reliabilityScore: _repo.reliabilityScore,
        incomingCount: _repo.incomingJobs.length,
        isAvailable: _repo.isAvailable,
        activeJob: _repo.activeJob,
      ),
    );
  }

  void toggleAvailability() {
    _repo.toggleAvailability();
    emit(state.copyWith(isAvailable: _repo.isAvailable));
  }
}
