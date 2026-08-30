import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'booking_flow_state.dart';

class BookingFlowCubit extends Cubit<BookingFlowState> {
  BookingFlowCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const BookingFlowState());

  final MockRepository _repo;

  void selectService(ServiceItem service) {
    emit(state.copyWith(service: service, step: BookingStatus.draft));
  }

  Future<void> submitBookingDetails({
    required String address,
    required DateTime scheduledAt,
  }) async {
    if (state.service == null) return;
    emit(state.copyWith(isLoading: true));
    await _repo.mockDelay();
    final booking = _repo.createBooking(
      state.service!,
      address: address,
    );
    emit(
      state.copyWith(
        booking: booking,
        address: address,
        scheduledAt: scheduledAt,
        step: BookingStatus.draft,
        isLoading: false,
      ),
    );
  }

  Future<void> confirmEstimate() async {
    emit(state.copyWith(isLoading: true));
    await _repo.mockDelay();
    emit(state.copyWith(isLoading: false, step: BookingStatus.draft));
  }

  Future<void> searchWorker() async {
    emit(state.copyWith(isLoading: true, step: BookingStatus.searching));
    await _repo.mockDelay();
    await Future<void>.delayed(const Duration(seconds: 2));
    _repo.advanceBooking(BookingStatus.searching);
    emit(state.copyWith(
      isLoading: false,
      step: BookingStatus.searching,
      booking: _repo.activeBooking,
    ));
  }

  Future<void> workerAccepted() async {
    emit(state.copyWith(isLoading: true));
    await _repo.mockDelay();
    _repo.advanceBooking(
      BookingStatus.accepted,
      workerId: 'w1',
      workerName: 'Rajesh Kumar',
    );
    emit(state.copyWith(
      isLoading: false,
      step: BookingStatus.accepted,
      booking: _repo.activeBooking,
    ));
  }

  Future<void> startWork() async {
    emit(state.copyWith(isLoading: true));
    await _repo.mockDelay();
    _repo.advanceBooking(BookingStatus.inProgress);
    emit(state.copyWith(
      isLoading: false,
      step: BookingStatus.inProgress,
      booking: _repo.activeBooking,
    ));
  }

  Future<void> completePayment() async {
    emit(state.copyWith(isLoading: true));
    await _repo.mockDelay();
    _repo.advanceBooking(BookingStatus.paid);
    emit(state.copyWith(
      isLoading: false,
      step: BookingStatus.paid,
      booking: _repo.activeBooking,
    ));
  }

  void reset() {
    _repo.activeBooking = null;
    emit(const BookingFlowState());
  }
}
