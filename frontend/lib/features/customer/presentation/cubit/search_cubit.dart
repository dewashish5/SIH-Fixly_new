import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/app_location.dart';
import '../../../../shared/models/models.dart';
import '../../../home/data/home_api_repository.dart';
import '../../../workers/data/workers_api_repository.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    HomeApiRepository? homeRepository,
    WorkersApiRepository? workersRepository,
    String? initialQuery,
  })  : _home = homeRepository ?? HomeApiRepository(),
        _workers = workersRepository ?? WorkersApiRepository(),
        super(SearchState(query: initialQuery ?? '')) {
    _warmCache();
  }

  final HomeApiRepository _home;
  final WorkersApiRepository _workers;
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

    if (q.isNotEmpty) {
      await _loadWorkers(q);
    }
  }

  void clear() {
    emit(const SearchState());
  }

  Future<void> filterByCategory(String categoryId) async {
    emit(state.copyWith(
      query: categoryId,
      categoryId: categoryId,
      isSearching: true,
      isLoadingWorkers: true,
    ));

    if (_all.isEmpty) {
      try {
        _all = await _home.fetchAllServices();
      } catch (_) {}
    }

    final normalized = categoryId.toLowerCase();
    final results = _all
        .where(
          (s) =>
              s.categoryId.toLowerCase() == normalized ||
              s.categoryId.toLowerCase().contains(normalized) ||
              normalized.contains(s.categoryId.toLowerCase()) ||
              (normalized == 'plumber' && s.categoryId.startsWith('plum')),
        )
        .toList();

    emit(state.copyWith(results: results, isSearching: false));

    await _loadWorkers(categoryId);
  }

  Future<void> _loadWorkers(String categoryOrSkill) async {
    emit(state.copyWith(isLoadingWorkers: true));
    try {
      final loc = AppLocation.instance;
      final lat = loc.hasFix ? loc.lat : 28.6139; // fallback coordinate if GPS not fixed
      final lng = loc.hasFix ? loc.lng : 77.2090;

      final workers = await _workers.fetchNearby(
        category: categoryOrSkill,
        sortBy: 'top_rated',
        lat: lat,
        lng: lng,
      );

      final normalizedTarget = categoryOrSkill.toLowerCase().trim();

      // Top matching rank:
      // 1. Workers with skills explicitly matching target keyword/category
      // 2. Highest rating
      // 3. Number of jobs completed
      final sorted = List<WorkerProfile>.from(workers)..sort((a, b) {
        final aMatchesSkill = a.skills.any((s) =>
            s.toLowerCase().contains(normalizedTarget) ||
            normalizedTarget.contains(s.toLowerCase()));
        final bMatchesSkill = b.skills.any((s) =>
            s.toLowerCase().contains(normalizedTarget) ||
            normalizedTarget.contains(s.toLowerCase()));

        if (aMatchesSkill && !bMatchesSkill) return -1;
        if (!aMatchesSkill && bMatchesSkill) return 1;

        final ratingDiff = b.rating.compareTo(a.rating);
        if (ratingDiff != 0) return ratingDiff;

        return b.jobsCompleted.compareTo(a.jobsCompleted);
      });

      emit(state.copyWith(
        nearbyWorkers: sorted,
        isLoadingWorkers: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        nearbyWorkers: const [],
        isLoadingWorkers: false,
      ));
    }
  }

  Future<void> refresh() async {
    _all = const [];
    final q = state.query.trim();
    if (state.categoryId != null && state.categoryId!.isNotEmpty) {
      await filterByCategory(state.categoryId!);
    } else {
      await search(q);
    }
  }
}
