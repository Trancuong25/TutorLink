import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../../location/presentation/location_providers.dart';
import '../domain/search_models.dart';
import 'maps/tutor_map.dart';
import 'search_filters_sheet.dart';
import 'search_providers.dart';
import 'tutor_search_card.dart';

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
                    data: (result) => Column(
                      children: [
                        Text(
                          '${result.hits.length} gia sư · ${result.elapsed.inMilliseconds} ms',
                        ),
                        if (result.truncated)
                          const Text(
                            'Đã giới hạn 100 kết quả; hãy thu hẹp khu vực/bộ lọc.',
                          ),
                        if (result.hits.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Không tìm thấy gia sư. Hãy tăng bán kính hoặc bớt bộ lọc.',
                            ),
                          ),
                        Expanded(
                          child: map
                              ? TutorMap(
                                  key: ValueKey(
                                    '${location.point.latitude}/${location.point.longitude}',
                                  ),
                                  center: location.point,
                                  radiusKm: filters.radiusKm,
                                  hits: result.hits,
                                )
                              : ListView.builder(
                                  itemCount: result.hits.length,
                                  itemBuilder: (_, i) =>
                                      TutorSearchCard(hit: result.hits[i]),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
