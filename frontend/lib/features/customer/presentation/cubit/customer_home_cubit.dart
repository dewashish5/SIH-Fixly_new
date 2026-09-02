import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/models.dart';
import '../../../home/data/home_api_repository.dart';

part 'customer_home_state.dart';

class CustomerHomeCubit extends Cubit<CustomerHomeState> {
  CustomerHomeCubit({HomeApiRepository? homeRepository})
      : _home = homeRepository ?? HomeApiRepository(),
        super(const CustomerHomeState());

  final HomeApiRepository _home;

  Future<void> load() async {
    emit(state.copyWith(status: CustomerHomeStatus.loading));
    try {
      // Prefer authenticated home bundle; fall back to public categories.
      try {
        final bundle = await _home.fetchHome();
        emit(
          state.copyWith(
            status: CustomerHomeStatus.loaded,
            categories: _displayCategories(bundle.categories),
            popularServices: bundle.topServices.isNotEmpty
                ? bundle.topServices
                : await _home.fetchAllServices(),
          ),
        );
      } on ApiException {
        final categories = await _home.fetchCategories();
        final services = await _home.fetchAllServices();
        emit(
          state.copyWith(
            status: CustomerHomeStatus.loaded,
            categories: _displayCategories(categories),
            popularServices: services,
          ),
        );
      }
    } catch (_) {
      emit(state.copyWith(status: CustomerHomeStatus.error));
    }
  }

  void refresh() => load();

  static List<ServiceCategory> _displayCategories(
    List<ServiceCategory> fromApi,
  ) {
    if (fromApi.length >= ServiceCategories.all.length) {
      return fromApi;
    }
    final seen = <String>{};
    final merged = <ServiceCategory>[];
    for (final cat in ServiceCategories.all) {
      merged.add(cat);
      seen.add(cat.id);
    }
    for (final cat in fromApi) {
      if (!seen.contains(cat.id)) {
        merged.add(cat);
        seen.add(cat.id);
      }
    }
    return merged;
  }
}
