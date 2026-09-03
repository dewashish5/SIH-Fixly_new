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

  Future<void> load({bool forceNetwork = false}) async {
    emit(state.copyWith(status: CustomerHomeStatus.loading));
    try {
      try {
        final bundle = await _home.fetchHome(forceNetwork: forceNetwork);
        emit(
          state.copyWith(
            status: CustomerHomeStatus.loaded,
            categories: _displayCategories(bundle.categories),
            popularServices: bundle.topServices,
          ),
        );
      } on ApiException {
        final categories = await _home.fetchCategories();
        emit(
          state.copyWith(
            status: CustomerHomeStatus.loaded,
            categories: _displayCategories(categories),
            popularServices: const [],
          ),
        );
      }
    } catch (_) {
      emit(state.copyWith(status: CustomerHomeStatus.error));
    }
  }

  void refresh() => load(forceNetwork: true);

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
