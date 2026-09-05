import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../reviews/data/reviews_api_repository.dart';

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
      emit(
        state.copyWith(
          status: ActiveJobStatus.inProgress,
          error: e.message,
        ),
      );
    }
  }

  Future<void> verifyOtpAndStart({required String otp}) async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      await _bookings.verifyArrivalOtp(bookingId: state.job!.id, otp: otp);
      await _bookings.startJob(state.job!.id);
      final jobs = await _bookings.workerActive();
      emit(state.copyWith(
        status: ActiveJobStatus.inProgress,
        job: jobs.isEmpty ? state.job!.copyWith(rawStatus: 'IN_PROGRESS') : jobs.first,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  Future<void> addExtraParts(List<Map<String, dynamic>> parts) async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      await _bookings.addParts(bookingId: state.job!.id, extraItems: parts);
      final jobs = await _bookings.workerActive();
      emit(state.copyWith(
        status: ActiveJobStatus.inProgress,
        job: jobs.isEmpty ? state.job : jobs.first,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  Future<void> submitWorkerReview({required String bookingId, required String customerId, required int rating, String comment = '', List<String> traits = const []}) async {
    // Worker reviews customer — after job completion
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      await ReviewsApiRepository().submit(
        bookingId: bookingId,
        workerId: customerId, // reviewing the customer
        rating: rating,
        comment: comment,
        traits: traits,
      );
      emit(state.copyWith(status: ActiveJobStatus.reviewSubmitted));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }
}
