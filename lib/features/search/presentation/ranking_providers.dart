import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutor_ranking/tutor_ranking.dart';

import '../../auth/presentation/controllers/auth_providers.dart';
import '../../location/domain/location_point.dart';
import '../domain/ranking_config.dart';
import '../domain/search_models.dart';

class RankingSelection extends Notifier<RankingMode> {
  @override
  RankingMode build() {
    ref.watch(identityProvider.select((v) => v.asData?.value?.uid));
    return RankingMode.nearest;
  }

  void select(RankingMode mode) => state = mode;
}

final rankingModeProvider = NotifierProvider<RankingSelection, RankingMode>(
  RankingSelection.new,
);
final rankingConfigurationProvider =
    StreamProvider.autoDispose<RankingConfiguration>((ref) async* {
      ref.watch(identityProvider.select((v) => v.asData?.value?.uid));
      final fallback = RankingConfig.parse(
        jsonDecode(await rootBundle.loadString('config/ranking_defaults.json'))
            as Map<String, dynamic>,
      );
      // Cấu hình dự phòng là asset dùng chung với seed, không chôn trọng số trong thuật toán.
      yield RankingConfiguration(
        fallback,
        fallback,
        warning: 'Đang tải trọng số từ máy chủ; tạm dùng mặc định.',
      );
      try {
        await for (final snapshot
            in FirebaseFirestore.instance
                .doc('config/ranking_weights')
                .snapshots()) {
          yield RankingConfiguration.resolve(snapshot.data(), fallback);
        }
      } catch (_) {
        yield RankingConfiguration(
          fallback,
          fallback,
          warning: 'Không tải được trọng số. Đang dùng mặc định; thử lại khi có mạng.',
        );
      }
    });

RankingRequest toRankingRequest(SearchRequest r, LocationPoint center) =>
    RankingRequest(
      subject: r.subject,
      level: r.level,
      budget: r.budget?.toDouble(),
      slots: r.slots,
      radiusKm: r.radiusKm,
      center: Position(center.latitude, center.longitude),
    );
List<TutorCandidate> toCandidates(List<SearchHit> hits) => hits.map((h) {
  final t = h.tutor, p = t.approxLocation!;
  return TutorCandidate(
    uid: t.uid,
    subjects: t.subjects.toSet(),
    levels: t.levels.toSet(),
    slots: t.availability,
    position: Position(p.latitude, p.longitude),
    hourlyRate: t.hourlyRate.toDouble(),
    isAvailable: t.isAvailable,
    ratingAvg: t.ratingAvg,
    ratingCount: t.ratingCount,
  );
}).toList();
