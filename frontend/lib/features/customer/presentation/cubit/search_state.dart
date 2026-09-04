part of 'search_cubit.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.categoryId,
    this.results = const [],
    this.nearbyWorkers = const [],
    this.isSearching = false,
    this.isLoadingWorkers = false,
  });

  final String query;
  final String? categoryId;
  final List<ServiceItem> results;
  final List<WorkerProfile> nearbyWorkers;
  final bool isSearching;
  final bool isLoadingWorkers;

  SearchState copyWith({
    String? query,
    String? categoryId,
    List<ServiceItem>? results,
    List<WorkerProfile>? nearbyWorkers,
    bool? isSearching,
    bool? isLoadingWorkers,
  }) {
    return SearchState(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      results: results ?? this.results,
      nearbyWorkers: nearbyWorkers ?? this.nearbyWorkers,
      isSearching: isSearching ?? this.isSearching,
      isLoadingWorkers: isLoadingWorkers ?? this.isLoadingWorkers,
    );
  }

  @override
  List<Object?> get props => [
        query,
        categoryId,
        results,
        nearbyWorkers,
        isSearching,
        isLoadingWorkers,
      ];
}
