import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({MockRepository? repository, String? initialQuery})
      : _repo = repository ?? MockRepository.instance,
        super(SearchState(query: initialQuery ?? ''));

  final MockRepository _repo;

  Future<void> search(String query) async {
    emit(state.copyWith(query: query, isSearching: true));
    await _repo.mockDelay();
    final results = _repo.searchServices(query);
    emit(state.copyWith(results: results, isSearching: false));
  }

  void clear() {
    emit(const SearchState());
  }

  void filterByCategory(String categoryId) {
    final results = _repo.servicesByCategory(categoryId);
    emit(state.copyWith(
      query: categoryId,
      results: results,
      isSearching: false,
    ));
  }
}
