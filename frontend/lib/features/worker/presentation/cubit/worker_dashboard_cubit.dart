import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/data/auth_api_repository.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../payments/data/payments_api_repository.dart';
import '../../../workers/data/workers_api_repository.dart';

part 'worker_dashboard_state.dart';

class WorkerDashboardCubit extends Cubit<WorkerDashboardState> {
  WorkerDashboardCubit({
    AuthApiRepository? auth,
    BookingsApiRepository? bookings,
    PaymentsApiRepository? payments,
    WorkersApiRepository? workers,
  })  : _auth = auth ?? AuthApiRepository(),
        _bookings = bookings ?? BookingsApiRepository(),
        _payments = payments ?? PaymentsApiRepository(),
        _workers = workers ?? WorkersApiRepository(),
        super(const WorkerDashboardState());

  final AuthApiRepository _auth;
  final BookingsApiRepository _bookings;
  final PaymentsApiRepository _payments;
  final WorkersApiRepository _workers;

  Future<void> load() async {
    emit(state.copyWith(status: WorkerDashboardStatus.loading, clearError: true));
    try {
      final userId = await ApiServices.tokens.userId;
      if (userId == null || userId.isEmpty) {
        throw ApiException('Not signed in');
      }
      final results = await Future.wait([
        _auth.fetchMe(),
        _payments.workerEarningsSummary(),
        _workers.fetchAvailability(),
        _bookings.workerIncoming(),
        _bookings.workerActive(),
        _workers.fetchReliability(userId),
      ]);
      final user = results[0] as AppUser;
      final summary = results[1] as Map<String, dynamic>;
      final availability = results[2] as Map<String, dynamic>;
      final incoming = results[3] as List<WorkerJob>;
      final active = results[4] as List<WorkerJob>;
      final reliability = results[5] as Map<String, dynamic>;
      emit(
        WorkerDashboardState(
          status: WorkerDashboardStatus.loaded,
          workerName: user.name,
          todayEarnings: (summary['today'] as num?)?.toDouble() ?? 0,
          completedJobs: (summary['completedJobs'] as num?)?.toInt() ?? 0,
          reliabilityScore: (reliability['score'] as num?)?.toInt() ?? 0,
          incomingCount: incoming.length,
          isAvailable: availability['isOnline'] == true,
          activeJob: active.isEmpty ? null : active.first,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: WorkerDashboardStatus.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: WorkerDashboardStatus.failure, error: e.toString()));
    }
  }

  Future<void> toggleAvailability() async {
    final next = !state.isAvailable;
    try {
      final online = await _workers.setOnline(next);
      emit(state.copyWith(isAvailable: online));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}
