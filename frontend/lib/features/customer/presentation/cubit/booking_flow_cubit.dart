import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_config.dart';
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
  }) : _repo = repository ?? MockRepository.instance,
       _bookings = bookingsRepository ?? BookingsApiRepository(),
       _payments = paymentsRepository ?? PaymentsApiRepository(),
       _razorpay = razorpayCheckout ?? RazorpayCheckoutService(),
       super(const BookingFlowState());

  final MockRepository _repo;
  final BookingsApiRepository _bookings;
  final PaymentsApiRepository _payments;
  final RazorpayCheckoutService _razorpay;

  Timer? _statusPollTimer;
  io.Socket? _statusSocket;

  void selectService(ServiceItem service) {
    emit(state.copyWith(service: service, step: BookingStatus.draft));
  }

  /// Load an existing booking into state (e.g. from order history tap).
  void loadFromBooking(Booking booking) {
    _repo.activeBooking = booking;
    emit(state.copyWith(
      booking: booking,
      step: booking.status,
      clearError: true,
    ));
  }

  /// Start polling booking status every 5s (for finding-worker / accepted screens).
  void startStatusPolling(String bookingId) {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await refreshBooking();
    });
  }

  void stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  /// Connect to socket and listen for real-time booking_status_update events.
  void listenToSocketUpdates(String bookingId) {
    _statusSocket?.disconnect();
    _statusSocket?.dispose();

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _statusSocket = socket;

    socket.onConnect((_) {
      socket.emit('join_booking_room', bookingId);
    });

    void onStatusUpdate(dynamic data) async {
      // Refresh booking to get latest data including the new status
      await refreshBooking();
    }

    socket.on('booking_status_update', onStatusUpdate);
    socket.on('booking:status', onStatusUpdate);
    socket.on('status_update', onStatusUpdate);
    socket.connect();

    // Also start polling as fallback
    startStatusPolling(bookingId);
  }

  Future<void> submitBookingDetails({
    required String address,
    DateTime? scheduledAt,
    required String problemDescription,
    String? workerId,
    List<String> photoPaths = const [],
    List<String> videoPaths = const [],
  }) async {
    final service = state.service;
    if (service == null) {
      emit(state.copyWith(errorMessage: 'Please select a service first'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final booking = await _bookings.create(
        serviceId: service.id,
        addressLine: address,
        problemDescription: problemDescription,
        workerId: workerId,
        scheduledTime: scheduledAt,
        serviceTitle: service.title,
        photoPaths: photoPaths,
        videoPaths: videoPaths,
      );
      _repo.activeBooking = booking;
      emit(
        state.copyWith(
          booking: booking,
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
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(
      state.copyWith(
        isLoading: false,
        step: BookingStatus.searching,
        booking: state.booking,
      ),
    );
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
      emit(
        state.copyWith(
          isLoading: false,
          step: updated.workerId != null
              ? BookingStatus.accepted
              : BookingStatus.searching,
          booking: updated,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> refreshBooking([String? bookingId]) async {
    final idToFetch = bookingId ?? state.booking?.id;
    if (idToFetch == null) return;
    try {
      final updated = await _bookings.getById(
        idToFetch,
        serviceTitle: state.booking?.serviceTitle ?? 'Fixly Service',
      );
      _repo.activeBooking = updated;
      emit(state.copyWith(booking: updated, step: updated.status, clearError: true));
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  double _payableAmount([Booking? targetBooking]) {
    final booking = targetBooking ?? state.booking;
    final totalPrice = booking?.totalPrice;
    if (totalPrice != null && totalPrice > 0) {
      return totalPrice;
    }
    if (booking != null && booking.estimatedPrice > 0) {
      return booking.estimatedPrice;
    }
    if (state.priceEstimate != null && state.priceEstimate!.maxTotal > 0) {
      return state.priceEstimate!.maxTotal;
    }
    return state.service?.priceFrom ?? 0;
  }

  Future<bool> payWithRazorpay({
    String? bookingId,
    double? amountOverride,
    String? customerName,
    String? email,
    String? phone,
  }) async {
    final targetBookingId = bookingId ?? state.booking?.id;
    if (targetBookingId == null) return false;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await refreshBooking(targetBookingId);
      final current = state.booking;
      if (current == null) {
        throw ApiException('Booking details not found');
      }
      final amount = amountOverride ?? _payableAmount(current);
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

      await refreshBooking(current.id);
      final updated = state.booking ??
          current.copyWith(
            status: BookingStatus.paid,
            paymentStatus: 'PAID',
          );
      _repo.activeBooking = updated;
      emit(
        state.copyWith(
          isLoading: false,
          step: BookingStatus.paid,
          booking: updated,
        ),
      );
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
    _statusPollTimer?.cancel();
    _razorpay.dispose();
    return super.close();
  }
}
