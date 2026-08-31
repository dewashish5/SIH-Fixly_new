import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../payments/data/payments_api_repository.dart';

part 'booking_flow_state.dart';

class BookingFlowCubit extends Cubit<BookingFlowState> {
  BookingFlowCubit({
    MockRepository? repository,
    BookingsApiRepository? bookingsRepository,
    PaymentsApiRepository? paymentsRepository,
  })  : _repo = repository ?? MockRepository.instance,
        _bookings = bookingsRepository ?? BookingsApiRepository(),
        _payments = paymentsRepository ?? PaymentsApiRepository(),
        super(const BookingFlowState());

  final MockRepository _repo;
  final BookingsApiRepository _bookings;
  final PaymentsApiRepository _payments;

  void selectService(ServiceItem service) {
    emit(state.copyWith(service: service, step: BookingStatus.draft));
  }

  Future<void> submitBookingDetails({
    required String address,
    required DateTime scheduledAt,
  }) async {
    if (state.service == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final estimate = await _bookings.estimate(serviceId: state.service!.id);
      final booking = await _bookings.create(
        serviceId: state.service!.id,
        addressLine: address,
        problemDescription: state.service!.title,
        scheduledTime: scheduledAt,
        serviceTitle: state.service!.title,
      );
      final priced = booking.copyWith(
        estimatedPrice: estimate.maxTotal > 0
            ? estimate.maxTotal
            : booking.estimatedPrice,
      );
      _repo.activeBooking = priced;
      emit(
        state.copyWith(
          booking: priced,
          address: address,
          scheduledAt: scheduledAt,
          step: BookingStatus.searching,
          isLoading: false,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> confirmEstimate() async {
    emit(state.copyWith(isLoading: false, step: BookingStatus.draft));
  }

  Future<void> searchWorker() async {
    emit(state.copyWith(isLoading: true, step: BookingStatus.searching));
    // Backend creates booking already in SEARCHING; keep UX delay.
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(state.copyWith(
      isLoading: false,
      step: BookingStatus.searching,
      booking: state.booking,
    ));
  }

  Future<void> workerAccepted() async {
    final booking = state.booking;
    if (booking == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final updated = await _bookings.getById(
        booking.id,
        serviceTitle: booking.serviceTitle,
      );
      _repo.activeBooking = updated;
      emit(state.copyWith(
        isLoading: false,
        step: updated.workerId != null
            ? BookingStatus.accepted
            : BookingStatus.searching,
        booking: updated,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> startWork() async {
    final booking = state.booking;
    if (booking == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final updated = await _bookings.verifyArrivalOtp(
        bookingId: booking.id,
        otp: '8492',
        serviceTitle: booking.serviceTitle,
      );
      _repo.activeBooking = updated;
      emit(state.copyWith(
        isLoading: false,
        step: BookingStatus.inProgress,
        booking: updated.copyWith(status: BookingStatus.inProgress),
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> completePayment() async {
    final booking = state.booking;
    if (booking == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final amount =
          booking.estimatedPrice > 0 ? booking.estimatedPrice : 100.0;
      await _payments.createOrder(
        bookingId: booking.id,
        amount: amount,
      );
      await _bookings.complete(booking.id);
      final paid = booking.copyWith(status: BookingStatus.paid);
      _repo.activeBooking = paid;
      emit(state.copyWith(
        isLoading: false,
        step: BookingStatus.paid,
        booking: paid,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void reset() {
    _repo.activeBooking = null;
    emit(const BookingFlowState());
  }
}
