import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/models.dart';
import '../../../home/data/home_api_repository.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({HomeApiRepository? homeRepository, String? initialQuery})
      : _home = homeRepository ?? HomeApiRepository(),
        super(SearchState(query: initialQuery ?? '')) {
    _warmCache();
  }

  final HomeApiRepository _home;
  List<ServiceItem> _all = const [];

  Future<void> _warmCache() async {
    try {
      _all = await _home.fetchAllServices();
      if (state.query.isNotEmpty) {
        await search(state.query);
      }
    } catch (_) {}
  }

  Future<void> search(String query) async {
    emit(state.copyWith(query: query, isSearching: true));
    if (_all.isEmpty) {
      try {
        _all = await _home.fetchAllServices();
      } catch (_) {}
    }
    final q = query.trim().toLowerCase();
    final results = q.isEmpty
        ? _all
        : _all
            .where(
              (s) =>
                  s.title.toLowerCase().contains(q) ||
                  s.categoryId.toLowerCase().contains(q) ||
                  s.description.toLowerCase().contains(q),
            )
            .toList();
    emit(state.copyWith(results: results, isSearching: false));
  }

  void clear() {
    emit(const SearchState());
  }

  Future<void> filterByCategory(String categoryId) async {
    emit(state.copyWith(query: categoryId, isSearching: true));
    if (_all.isEmpty) {
      try {
        _all = await _home.fetchAllServices();
      } catch (_) {}
    }
    final results = _all
        .where(
          (s) =>
              s.categoryId == categoryId ||
              s.categoryId.toLowerCase().contains(categoryId.toLowerCase()) ||
              (categoryId == 'plumber' && s.categoryId.startsWith('plum')),
        )
        .toList();
    emit(state.copyWith(results: results, isSearching: false));
  }

  Future<void> refresh() async {
    _all = const [];
    final q = state.query.trim();
    final isCategory = ServiceCategories.all.any((c) => c.id == q);
    if (isCategory) {
      await filterByCategory(q);
    } else {
      await search(q);
    }
  }
}
