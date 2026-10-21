import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/controllers/auth_providers.dart';
import '../../location/presentation/location_providers.dart';
import '../data/firestore_search_repository.dart';
import '../domain/search_models.dart';

class SearchFilters extends Notifier<SearchRequest> {
  @override
  SearchRequest build() {
    ref.watch(identityProvider.select((v) => v.asData?.value?.uid));
    return const SearchRequest();
  }

  void apply(SearchRequest request) => state = request;
}

final searchFiltersProvider = NotifierProvider<SearchFilters, SearchRequest>(
  SearchFilters.new,
);
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => FirestoreSearchRepository(FirebaseFirestore.instance),
);
final searchResultsProvider = FutureProvider.autoDispose<SearchResult>((
  ref,
) async {
  final location = ref.watch(searchLocationProvider);
  final request = ref.watch(searchFiltersProvider);
  if (location == null) return const SearchResult([]);
  return ref
      .watch(searchRepositoryProvider)
      .search(location.point, request)
      .timeout(const Duration(seconds: 15));
});
