import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/worker_realtime_service.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../reviews/data/reviews_api_repository.dart';

part 'active_job_state.dart';

class ActiveJobCubit extends Cubit<ActiveJobState> {
  ActiveJobCubit({BookingsApiRepository? bookings})
      : _bookings = bookings ?? BookingsApiRepository(),
        super(const ActiveJobState());

  final BookingsApiRepository _bookings;
  StreamSubscription? _statusSub;

  Future<void> load() async {
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      final jobs = await _bookings.workerActive();
      final job = jobs.isEmpty ? null : jobs.first;

      if (job != null) {
        WorkerRealtimeService.instance.trackBooking(job.id);
        await AppPreferences.instance.setActiveWorkerJobId(job.id);
      } else {
        await AppPreferences.instance.setActiveWorkerJobId(null);
      }

      _statusSub?.cancel();
      _statusSub = WorkerRealtimeService.instance.bookingStatusStream.listen((data) {
        _onSocketStatusUpdate(data);
      });

      emit(
        ActiveJobState(
          status: ActiveJobStatus.loaded,
          job: job,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  void _onSocketStatusUpdate(Map<String, dynamic> data) {
    final currentJob = state.job;
    if (currentJob == null) return;

    final bookingId = data['bookingId']?.toString();
    final canonicalId = data['canonicalBookingId']?.toString();
    if (bookingId != currentJob.id && canonicalId != currentJob.id) {
      return;
    }

    final newStatus = data['status']?.toString();
    final paymentStatus = data['paymentStatus']?.toString();

    if (newStatus == 'COMPLETED') {
      emit(
        state.copyWith(
          status: ActiveJobStatus.completed,
          job: currentJob.copyWith(
            status: JobStatus.completed,
            rawStatus: 'COMPLETED',
          ),
        ),
      );
    } else if (paymentStatus == 'PAID') {
      emit(
        state.copyWith(
          status: ActiveJobStatus.inProgress,
          job: currentJob.copyWith(
            rawStatus: 'PAYMENT_PAID',
            invoice: data['invoice'] != null ? BookingInvoice.fromJson(data['invoice']) : currentJob.invoice,
          ),
        ),
      );
    } else if (newStatus == 'PAYMENT_PENDING') {
      emit(
        state.copyWith(
          status: ActiveJobStatus.inProgress,
          job: currentJob.copyWith(rawStatus: 'PAYMENT_PENDING'),
        ),
      );
    } else if (newStatus == 'IN_PROGRESS') {
      emit(
        state.copyWith(
          status: ActiveJobStatus.inProgress,
          job: currentJob.copyWith(rawStatus: 'IN_PROGRESS'),
        ),
      );
    }
  }

  Future<void> completeJob() async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading));
    try {
      final res = await _bookings.complete(state.job!.id);
      // If backend moved to PAYMENT_PENDING awaiting customer payment
      if (res['status'] == 'PAYMENT_PENDING' || res['booking']?['status'] == 'PAYMENT_PENDING') {
        emit(
          state.copyWith(
            status: ActiveJobStatus.inProgress,
            job: state.job!.copyWith(rawStatus: 'PAYMENT_PENDING'),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ActiveJobStatus.completed,
            job: state.job!.copyWith(status: JobStatus.completed, rawStatus: 'COMPLETED'),
          ),
        );
      }
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
      await AppPreferences.instance.setActiveWorkerJobId(null);
      emit(state.copyWith(status: ActiveJobStatus.reviewSubmitted));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    return super.close();
  }
}

