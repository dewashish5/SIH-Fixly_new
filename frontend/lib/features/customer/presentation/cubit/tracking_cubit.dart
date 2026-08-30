import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const TrackingState());

  final MockRepository _repo;
  Timer? _timer;

  void startTracking({String? workerName}) {
    _timer?.cancel();
    final name =
        workerName ?? _repo.activeBooking?.workerName ?? 'Rajesh Kumar';
    emit(TrackingState(
      isActive: true,
      progress: 0,
      workerName: name,
      etaMinutes: 12,
      phase: TrackingPhase.enRoute,
    ));

    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final next = state.progress + 0.05;
      if (next >= 1) {
        timer.cancel();
        emit(state.copyWith(
          progress: 1,
          etaMinutes: 0,
          phase: TrackingPhase.arrived,
          isActive: false,
        ));
        return;
      }
      final eta = ((1 - next) * 12).ceil();
      final phase = next < 0.5
          ? TrackingPhase.enRoute
          : next < 0.85
              ? TrackingPhase.nearby
              : TrackingPhase.arriving;
      emit(state.copyWith(progress: next, etaMinutes: eta, phase: phase));
    });
  }

  void reset() {
    _timer?.cancel();
    emit(const TrackingState());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
