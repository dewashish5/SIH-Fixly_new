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
    this.priceEstimate,
    this.errorMessage,
  });

  final ServiceItem? service;
  final Booking? booking;
  final BookingStatus step;
  final String? address;
  final DateTime? scheduledAt;
  final bool isLoading;
  final double? estimatedPrice;
  final PriceEstimate? priceEstimate;
  final String? errorMessage;

  double get displayPrice {
    final totalPrice = booking?.totalPrice;
    if (totalPrice != null && totalPrice > 0) {
      return totalPrice;
    }
    if (booking != null && booking!.estimatedPrice > 0) {
      return booking!.estimatedPrice;
    }
    if (priceEstimate != null && priceEstimate!.maxTotal > 0) {
      return priceEstimate!.maxTotal;
    }
    return estimatedPrice ?? service?.priceFrom ?? 0;
  }

  BookingFlowState copyWith({
    ServiceItem? service,
    Booking? booking,
    BookingStatus? step,
    String? address,
    DateTime? scheduledAt,
    bool? isLoading,
    double? estimatedPrice,
    PriceEstimate? priceEstimate,
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
      priceEstimate: priceEstimate ?? this.priceEstimate,
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
        priceEstimate,
        errorMessage,
      ];
}
