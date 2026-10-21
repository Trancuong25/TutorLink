import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutor_ranking/tutor_ranking.dart';

import '../../location/domain/location_point.dart';
import '../domain/search_models.dart';
import 'maps/tutor_map.dart';
import 'ranking_providers.dart';
import 'tutor_search_card.dart';

class RankedResults extends ConsumerWidget {
  const RankedResults({
    super.key,
    required this.result,
    required this.request,
    required this.center,
    required this.map,
  });
  final SearchResult result;
  final SearchRequest request;
  final LocationPoint center;
  final bool map;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(rankingModeProvider);
    var hits = result.hits;
    final explanations = <String, RankedTutor>{};
    String? warning;
    if (mode == RankingMode.bestMatch) {
      final config = ref.watch(rankingConfigurationProvider);
      if (config.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (config.hasError) {
        return Center(
          child: TextButton(
            onPressed: () => ref.invalidate(rankingConfigurationProvider),
            child: const Text('Không tải được cấu hình. Thử lại'),
          ),
        );
      }
      final bundle = config.requireValue;
      var selected = bundle.current;
      warning = bundle.warning;
      final rankingRequest = toRankingRequest(request, center);
      try {
        selected.weights.effective(rankingRequest);
      } catch (_) {
        selected = bundle.fallback;
        warning = 'Trọng số còn lại bằng 0 khi bỏ tiêu chí trống. Đang dùng mặc định.';
      }
      final ranked = rankTutors(
        toCandidates(hits),
        rankingRequest,
        selected.weights,
        selected.systemMean,
      );
      final byId = {for (final h in hits) h.tutor.uid: h};
      hits = ranked.map((r) => byId[r.tutor.uid]!).toList();
      explanations.addAll({for (final r in ranked) r.tutor.uid: r});
    }
    Widget? explain(SearchHit h) {
      final r = explanations[h.tutor.uid];
      if (r == null) return null;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vì sao phù hợp · ${(r.score * 100).toStringAsFixed(1)} điểm',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final reason in r.reasons) Text('• $reason'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text('${hits.length} gia sư'),
        if (warning != null)
          Padding(padding: const EdgeInsets.all(8), child: Text(warning)),
        if (result.truncated)
          const Text(
            'Kết quả bị giới hạn; hãy thu hẹp khu vực/bộ lọc. Hai chế độ dùng cùng tập này.',
          ),
        if (hits.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Không tìm thấy gia sư. Hãy tăng bán kính hoặc bớt bộ lọc.',
            ),
          ),
        Expanded(
          child: map
              ? TutorMap(
                  key: ValueKey('${center.latitude}/${center.longitude}'),
                  center: center,
                  radiusKm: request.radiusKm,
                  hits: hits,
                  explanationBuilder: explain,
                )
              : ListView.builder(
                  itemCount: hits.length,
                  itemBuilder: (_, i) => TutorSearchCard(
                    hit: hits[i],
                    explanation: explain(hits[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
