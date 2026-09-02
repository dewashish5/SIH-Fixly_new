import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../payments/data/payments_api_repository.dart';
import '../../../payments/services/razorpay_checkout_service.dart';

part 'booking_flow_state.dart';

class BookingFlowCubit extends Cubit<BookingFlowState> {
  BookingFlowCubit({
    MockRepository? repository,
    BookingsApiRepository? bookingsRepository,
    PaymentsApiRepository? paymentsRepository,
    RazorpayCheckoutService? razorpayCheckout,
  })  : _repo = repository ?? MockRepository.instance,
        _bookings = bookingsRepository ?? BookingsApiRepository(),
        _payments = paymentsRepository ?? PaymentsApiRepository(),
        _razorpay = razorpayCheckout ?? RazorpayCheckoutService(),
        super(const BookingFlowState());

  final MockRepository _repo;
  final BookingsApiRepository _bookings;
  final PaymentsApiRepository _payments;
  final RazorpayCheckoutService _razorpay;

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
          priceEstimate: estimate,
          estimatedPrice: estimate.maxTotal,
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

  Future<void> refreshBooking() async {
    final booking = state.booking;
    if (booking == null) return;
    try {
      final updated = await _bookings.getById(
        booking.id,
        serviceTitle: booking.serviceTitle,
      );
      _repo.activeBooking = updated;
      emit(state.copyWith(booking: updated, clearError: true));
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  double _payableAmount() {
    final booking = state.booking;
    if (booking != null && booking.estimatedPrice > 0) {
      return booking.estimatedPrice;
    }
    if (state.priceEstimate != null && state.priceEstimate!.maxTotal > 0) {
      return state.priceEstimate!.maxTotal;
    }
    return state.service?.priceFrom ?? 0;
  }

  Future<bool> payWithRazorpay({
    String? customerName,
    String? email,
    String? phone,
  }) async {
    final booking = state.booking;
    if (booking == null) return false;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await refreshBooking();
      final current = state.booking ?? booking;
      final amount = _payableAmount();
      if (amount <= 0) {
        throw ApiException('Invalid payment amount');
      }

      await _payments.fetchConfig();
      final order = await _payments.createOrder(
        bookingId: current.id,
        amountRupees: amount,
      );

      final result = await _razorpay.openCheckout(
        order: order,
        description: '${current.serviceTitle} payment',
        customerName: customerName,
        email: email,
        phone: phone,
      );

      final verified = await _payments.verify(
        razorpayOrderId: result.orderId,
        razorpayPaymentId: result.paymentId,
        razorpaySignature: result.signature,
        bookingId: current.id,
      );
      if (!verified) {
        throw ApiException('Payment verification failed');
      }

      final paid = current.copyWith(status: BookingStatus.paid);
      _repo.activeBooking = paid;
      emit(state.copyWith(
        isLoading: false,
        step: BookingStatus.paid,
        booking: paid,
      ));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return false;
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> completeCashPayment() async {
    final booking = state.booking;
    if (booking == null) return false;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await refreshBooking();
      final current = state.booking ?? booking;
      await _bookings.complete(current.id);
      final completed = current.copyWith(status: BookingStatus.completed);
      _repo.activeBooking = completed;
      emit(state.copyWith(
        isLoading: false,
        step: BookingStatus.completed,
        booking: completed,
      ));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return false;
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      return false;
    }
  }

  void reset() {
    _razorpay.dispose();
    _repo.activeBooking = null;
    emit(const BookingFlowState());
  }

  @override
  Future<void> close() {
    _razorpay.dispose();
    return super.close();
  }
}
