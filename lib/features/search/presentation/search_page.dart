import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutor_ranking/tutor_ranking.dart';

import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../../location/presentation/location_providers.dart';
import '../domain/search_models.dart';
import 'ranked_results.dart';
import 'ranking_providers.dart';
import 'search_filters_sheet.dart';
import 'search_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  bool map = false;
  @override
  Widget build(BuildContext context) {
    final location = ref.watch(searchLocationProvider);
    final filters = ref.watch(searchFiltersProvider);
    final results = ref.watch(searchResultsProvider);
    final rankingMode = ref.watch(rankingModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm gia sư'),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final request = await showModalBottomSheet<SearchRequest>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => FractionallySizedBox(
                  heightFactor: 0.9,
                  child: SearchFiltersSheet(initial: filters),
                ),
              );
              if (request != null && mounted) {
                ref.read(searchFiltersProvider.notifier).apply(request);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TextButton.icon(
            onPressed: () => context.push('/location'),
            icon: const Icon(Icons.my_location),
            label: Text(location?.label ?? 'Chọn khu vực hoặc dùng GPS'),
          ),
          Text(
            '${catalog.subjects[filters.subject]} · bán kính ${filters.radiusKm.round()} km',
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Danh sách'),
                icon: Icon(Icons.list),
              ),
              ButtonSegment(
                value: true,
                label: Text('Bản đồ'),
                icon: Icon(Icons.map_outlined),
              ),
            ],
            selected: {map},
            onSelectionChanged: (v) => setState(() => map = v.first),
          ),
          const SizedBox(height: 8),
          SegmentedButton<RankingMode>(
            segments: const [
              ButtonSegment(
                value: RankingMode.nearest,
                label: Text('Gần nhất'),
              ),
              ButtonSegment(
                value: RankingMode.bestMatch,
                label: Text('Phù hợp nhất'),
              ),
            ],
            selected: {rankingMode},
            onSelectionChanged: (v) =>
                ref.read(rankingModeProvider.notifier).select(v.first),
          ),
          if (map)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Nền bản đồ do bên thứ ba cung cấp; họ nhận IP và vùng bản đồ đang xem.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          Expanded(
            child: location == null
                ? const Center(
                    child: Text(
                      'Chưa chọn vị trí tìm kiếm.\nBạn có thể từ chối GPS và nhập khu vực thủ công.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Không tải được gia sư. Kiểm tra mạng và thử lại.',
                          ),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(searchResultsProvider),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                    data: (result) => RankedResults(
                      result: result,
                      request: filters,
                      center: location.point,
                      map: map,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
