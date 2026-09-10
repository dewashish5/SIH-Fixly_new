import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
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
  bool _finalizeInFlight = false;

  Future<void> load() async {
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      final userId = await ApiServices.tokens.userId;
      if (userId != null && userId.isNotEmpty) {
        WorkerRealtimeService.instance.initForWorker(userId);
      }

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

    if (paymentStatus == 'PAID' || newStatus == 'COMPLETED') {
      emit(
        state.copyWith(
          status: ActiveJobStatus.paymentReceived,
          job: currentJob.copyWith(
            status: JobStatus.completed,
            rawStatus: 'PAYMENT_PAID',
            invoice: data['invoice'] is Map
                ? BookingInvoice.fromJson(
                    Map<String, dynamic>.from(data['invoice'] as Map),
                  )
                : currentJob.invoice,
          ),
        ),
      );
      return;
    }

    if (newStatus == null || newStatus.isEmpty) return;

    emit(
      state.copyWith(
        status: ActiveJobStatus.inProgress,
        job: currentJob.copyWith(
          rawStatus: newStatus,
          invoice: data['invoice'] is Map
              ? BookingInvoice.fromJson(
                  Map<String, dynamic>.from(data['invoice'] as Map),
                )
              : currentJob.invoice,
        ),
      ),
    );
  }

  Future<void> completeJob() async {
    if (state.job == null || _finalizeInFlight) return;
    _finalizeInFlight = true;
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      final res = await _bookings.complete(state.job!.id);
      final nextStatus =
          res['status']?.toString() ?? res['booking']?['status']?.toString();
      if (nextStatus == 'PAYMENT_PENDING') {
        emit(
          state.copyWith(
            status: ActiveJobStatus.awaitingPayment,
            job: state.job!.copyWith(rawStatus: 'PAYMENT_PENDING'),
          ),
        );
      } else if (nextStatus == 'COMPLETED') {
        emit(
          state.copyWith(
            status: ActiveJobStatus.paymentReceived,
            job: state.job!.copyWith(
              status: JobStatus.completed,
              rawStatus: 'PAYMENT_PAID',
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ActiveJobStatus.inProgress,
            job: state.job!.copyWith(rawStatus: nextStatus ?? state.job!.rawStatus),
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
    } finally {
      _finalizeInFlight = false;
    }
  }

  /// Arrival OTP only — does not start work.
  Future<void> verifyArrivalOtp({required String otp}) async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      await _bookings.verifyArrivalOtp(bookingId: state.job!.id, otp: otp);
      final jobs = await _bookings.workerActive();
      emit(
        state.copyWith(
          status: ActiveJobStatus.loaded,
          job: jobs.isEmpty
              ? state.job!.copyWith(rawStatus: 'ARRIVED')
              : jobs.first,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  Future<void> startJob() async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      await _bookings.startJob(state.job!.id);
      final jobs = await _bookings.workerActive();
      emit(
        state.copyWith(
          status: ActiveJobStatus.inProgress,
          job: jobs.isEmpty
              ? state.job!.copyWith(rawStatus: 'IN_PROGRESS')
              : jobs.first,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  Future<void> addExtraParts(
    List<Map<String, dynamic>> parts, {
    bool replace = false,
  }) async {
    if (state.job == null) return;
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      await _bookings.addParts(
        bookingId: state.job!.id,
        extraItems: parts,
        replace: replace,
      );
      final jobs = await _bookings.workerActive();
      emit(
        state.copyWith(
          status: ActiveJobStatus.inProgress,
          job: jobs.isEmpty ? state.job : jobs.first,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ActiveJobStatus.failure, error: e.message));
    }
  }

  /// Single-shot final billing → request payment. Prevents duplicate part stacks.
  Future<void> finalizeBillingAndRequestPayment(
    List<Map<String, dynamic>> parts,
  ) async {
    if (state.job == null || _finalizeInFlight) return;
    _finalizeInFlight = true;
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      if (parts.isNotEmpty) {
        await _bookings.addParts(
          bookingId: state.job!.id,
          extraItems: parts,
          replace: true,
        );
      }
      final res = await _bookings.complete(state.job!.id);
      final nextStatus =
          res['status']?.toString() ?? res['booking']?['status']?.toString();
      final jobs = await _bookings.workerActive();
      final job = jobs.isEmpty
          ? state.job!.copyWith(rawStatus: nextStatus ?? 'PAYMENT_PENDING')
          : jobs.first;
      emit(
        state.copyWith(
          status: nextStatus == 'COMPLETED'
              ? ActiveJobStatus.paymentReceived
              : ActiveJobStatus.awaitingPayment,
          job: job.copyWith(
            rawStatus: nextStatus == 'COMPLETED' ? 'PAYMENT_PAID' : 'PAYMENT_PENDING',
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ActiveJobStatus.failure,
          error: e.message,
        ),
      );
    } finally {
      _finalizeInFlight = false;
    }
  }

  Future<void> submitWorkerReview({
    required String bookingId,
    required String customerId,
    required int rating,
    String comment = '',
    List<String> traits = const [],
    List<String> photoPaths = const [],
  }) async {
    emit(state.copyWith(status: ActiveJobStatus.loading, clearError: true));
    try {
      await ReviewsApiRepository().submit(
        bookingId: bookingId,
        workerId: customerId,
        rating: rating,
        comment: comment,
        traits: traits,
        photoPaths: photoPaths,
        reviewerRole: 'worker',
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
