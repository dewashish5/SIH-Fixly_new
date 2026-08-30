import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'customer_home_state.dart';

class CustomerHomeCubit extends Cubit<CustomerHomeState> {
  CustomerHomeCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const CustomerHomeState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: CustomerHomeStatus.loading));
    await _repo.mockDelay();
    emit(
      state.copyWith(
        status: CustomerHomeStatus.loaded,
        categories: ServiceCategories.all,
        popularServices: _repo.services,
      ),
    );
  }

  void refresh() => load();
}
