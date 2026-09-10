import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/customer_realtime_service.dart';
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
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  String? _listeningBookingId;

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
    listenToSocketUpdates(booking.id);
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
    if (bookingId.isEmpty) return;
    if (_listeningBookingId == bookingId && _statusSubscription != null) return;
    _listeningBookingId = bookingId;
    CustomerRealtimeService.instance.trackBooking(bookingId);

    _statusSubscription?.cancel();
    _statusSubscription = CustomerRealtimeService.instance.bookingStatusStream.listen((map) async {
      final eventBookingId = map['bookingId']?.toString();
      final canonicalId = map['canonicalBookingId']?.toString();
      final current = state.booking;
      if (current != null &&
          eventBookingId != null &&
          eventBookingId != current.id &&
          canonicalId != current.id &&
          eventBookingId != bookingId) {
        return;
      }

      final newStatus = map['status']?.toString();
      final paymentStatus = map['paymentStatus']?.toString();

      // Instant UI from socket payload, then hydrate via API.
      if (current != null && (newStatus != null || paymentStatus != null)) {
        final mapped = BookingsApiRepository.mapStatus(newStatus ?? current.rawStatus);
        emit(
          state.copyWith(
            booking: current.copyWith(
              status: paymentStatus == 'PAID' ? BookingStatus.paid : mapped,
              rawStatus: paymentStatus == 'PAID'
                  ? 'COMPLETED'
                  : (newStatus ?? current.rawStatus),
              paymentStatus: paymentStatus ?? current.paymentStatus,
            ),
            step: paymentStatus == 'PAID' ? BookingStatus.paid : mapped,
          ),
        );
      }
      await refreshBooking(bookingId);
    });

    // Polling as fallback when socket drops
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
      listenToSocketUpdates(booking.id);
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
      // Keep socket joined for live status without manual reload.
      listenToSocketUpdates(updated.id);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  double _payableAmount([Booking? targetBooking]) {
    final booking = targetBooking ?? state.booking;
    if (booking?.totalAmount != null && booking!.totalAmount! > 0) {
      return booking.totalAmount!;
    }
    if (booking?.invoice?.totalAmount != null && booking!.invoice!.totalAmount > 0) {
      return booking.invoice!.totalAmount;
    }
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
          step: BookingStatus.rating,
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
    _statusPollTimer?.cancel();
    _statusSubscription?.cancel();
    CustomerRealtimeService.instance.untrackBooking();
    _listeningBookingId = null;
    _razorpay.dispose();
    _repo.activeBooking = null;
    emit(const BookingFlowState());
  }

  @override
  Future<void> close() {
    _statusPollTimer?.cancel();
    _statusSubscription?.cancel();
    CustomerRealtimeService.instance.untrackBooking();
    _razorpay.dispose();
    return super.close();
  }
}
