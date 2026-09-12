part of 'customer_home_cubit.dart';

enum CustomerHomeStatus { initial, loading, loaded, error }

class CustomerHomeState extends Equatable {
  const CustomerHomeState({
    this.status = CustomerHomeStatus.initial,
    this.categories = const [],
    this.popularServices = const [],
    this.banners = const [],
  });

  final CustomerHomeStatus status;
  final List<ServiceCategory> categories;
  final List<ServiceItem> popularServices;
  final List<CouponBanner> banners;

  CustomerHomeState copyWith({
    CustomerHomeStatus? status,
    List<ServiceCategory>? categories,
    List<ServiceItem>? popularServices,
    List<CouponBanner>? banners,
  }) {
    return CustomerHomeState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      popularServices: popularServices ?? this.popularServices,
      banners: banners ?? this.banners,
    );
  }

  @override
  List<Object?> get props => [status, categories, popularServices, banners];
}
