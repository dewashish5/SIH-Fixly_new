part of 'booking_flow_cubit.dart';

class BookingFlowState extends Equatable {
  const BookingFlowState({
    this.service,
    this.booking,
    this.step = BookingStatus.draft,
    this.address,
    this.scheduledAt,
    this.isLoading = false,
    this.estimatedPrice,
    this.errorMessage,
  });

  final ServiceItem? service;
  final Booking? booking;
  final BookingStatus step;
  final String? address;
  final DateTime? scheduledAt;
  final bool isLoading;
  final double? estimatedPrice;
  final String? errorMessage;

  double get displayPrice =>
      estimatedPrice ?? booking?.estimatedPrice ?? service?.priceFrom ?? 0;

  BookingFlowState copyWith({
    ServiceItem? service,
    Booking? booking,
    BookingStatus? step,
    String? address,
    DateTime? scheduledAt,
    bool? isLoading,
    double? estimatedPrice,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookingFlowState(
      service: service ?? this.service,
      booking: booking ?? this.booking,
      step: step ?? this.step,
      address: address ?? this.address,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isLoading: isLoading ?? this.isLoading,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        service,
        booking,
        step,
        address,
        scheduledAt,
        isLoading,
        estimatedPrice,
        errorMessage,
      ];
}
