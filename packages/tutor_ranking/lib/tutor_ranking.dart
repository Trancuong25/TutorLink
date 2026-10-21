library;

import 'dart:collection';
import 'dart:math' as math;

enum RankingMode { nearest, bestMatch }

class Position {
  const Position(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;
}

double haversineKm(Position a, Position b) {
  if (!a.valid || !b.valid) throw ArgumentError('Tọa độ không hợp lệ');
  final lat = (b.latitude - a.latitude) * math.pi / 180;
  final lon = (b.longitude - a.longitude) * math.pi / 180;
  final h =
      math.pow(math.sin(lat / 2), 2) +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          math.pow(math.sin(lon / 2), 2);
  // Giữ cùng thứ tự tính với bộ lọc tìm kiếm để không lệch tập ở sát biên R.
  return 2 * 6371000 * math.asin(math.sqrt(h.clamp(0, 1))) / 1000;
}

class TutorCandidate {
  const TutorCandidate({
    required this.uid,
    required this.subjects,
    required this.levels,
    required this.slots,
    required this.position,
    required this.hourlyRate,
    this.isAvailable = true,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });
  final String uid;
  final Set<String> subjects, levels;
  final Set<int> slots;
  final Position position;
  final double hourlyRate, ratingAvg;
  final int ratingCount;
  final bool isAvailable;
}

class RankingRequest {
  const RankingRequest({
    required this.subject,
    required this.center,
    required this.radiusKm,
    this.level,
    this.budget,
    this.slots = const {},
  });
  final String subject;
  final String? level;
  final Position center;
  final double radiusKm;
  final double? budget;
  final Set<int> slots;
}

class RankingWeights {
  RankingWeights(Map<String, double> values)
    : values = Map.unmodifiable(values) {
    if (values.length != keys.length ||
        !keys.every(values.containsKey) ||
        values.values.any((v) => !v.isFinite || v < 0) ||
        (values.values.fold(0.0, (a, b) => a + b) - 1).abs() > 0.000001) {
      throw ArgumentError('Trọng số phải không âm, hữu hạn và tổng bằng 1.');
    }
  }
  static const keys = ['subject', 'schedule', 'distance', 'price', 'rating'];
  final Map<String, double> values;
  Map<String, double> effective(RankingRequest request) {
    // Bỏ tiêu chí thiếu đầu vào, chia lại trọng số trên các tiêu chí còn lại.
    final active = {
      for (final key in keys)
        if (!(key == 'schedule' && request.slots.isEmpty) &&
            !(key == 'price' && request.budget == null))
          key: values[key]!,
    };
    final sum = active.values.fold(0.0, (a, b) => a + b);
    if (sum <= 0)
      throw ArgumentError('Không còn trọng số dương cho yêu cầu này.');
    return Map.unmodifiable(
      active.map((key, value) => MapEntry(key, value / sum)),
    );
  }
}

class RankedTutor {
  const RankedTutor({
    required this.tutor,
    required this.score,
    required this.components,
    required this.effectiveWeights,
    required this.distanceKm,
    required this.reasons,
  });
  final TutorCandidate tutor;
  final double score, distanceKm;
  final Map<String, double?> components;
  final Map<String, double> effectiveWeights;
  final List<String> reasons;
}

class RankingResult extends IterableBase<RankedTutor> {
  RankingResult(Iterable<RankedTutor> ranked, Iterable<String> skipped)
    : rankedTutors = List.unmodifiable(ranked),
      skippedUids = List.unmodifiable(skipped);

  final List<RankedTutor> rankedTutors;
  final List<String> skippedUids;

  @override
  Iterator<RankedTutor> get iterator => rankedTutors.iterator;
}

double scheduleCoverage(Set<int> available, Set<int> needed) {
  // Độ phủ không phạt gia sư có thêm buổi rảnh ngoài nhu cầu.
  return needed.isEmpty
      ? 0
      : available.intersection(needed).length / needed.length;
}

double priceScore(double price, double budget) {
  if (!price.isFinite || price < 0 || !budget.isFinite || budget <= 0)
    throw ArgumentError('Giá/ngân sách không hợp lệ');
  return (2 - price / budget).clamp(0.0, 1.0);
}

double bayesianRating(double average, int count, double systemMean) {
  if (!average.isFinite ||
      average < 0 ||
      average > 5 ||
      count < 0 ||
      !systemMean.isFinite ||
      systemMean < 0 ||
      systemMean > 5) {
    throw ArgumentError('Đánh giá không hợp lệ');
  }
  return ((count * average + 5 * systemMean) / (count + 5) / 5).clamp(0.0, 1.0);
}

RankingResult rankTutors(
  Iterable<TutorCandidate> candidates,
  RankingRequest request,
  RankingWeights weights,
  double systemMean, {
  RankingMode mode = RankingMode.bestMatch,
}) {
  if (request.subject.isEmpty ||
      !request.center.valid ||
      !request.radiusKm.isFinite ||
      request.radiusKm <= 0 ||
      (request.budget != null &&
          (!request.budget!.isFinite || request.budget! <= 0)) ||
      request.slots.any((s) => s < 0 || s > 20))
    throw ArgumentError('Yêu cầu không hợp lệ');
  bayesianRating(0, 0, systemMean);
  final effective = weights.effective(request);
  final ranked = <RankedTutor>[];
  final skipped = <String>[];
  for (final tutor in candidates) {
    // Một hồ sơ lỗi không làm hỏng toàn bộ kết quả tìm kiếm.
    if (!tutor.position.valid ||
        !tutor.hourlyRate.isFinite ||
        tutor.hourlyRate < 0 ||
        tutor.slots.any((s) => s < 0 || s > 20) ||
        !tutor.ratingAvg.isFinite ||
        tutor.ratingAvg < 0 ||
        tutor.ratingAvg > 5 ||
        tutor.ratingCount < 0) {
      skipped.add(tutor.uid);
      continue;
    }
    if (!tutor.isAvailable || !tutor.subjects.contains(request.subject))
      continue;
    final distance = haversineKm(request.center, tutor.position);
    if (distance > request.radiusKm) continue;
    final components = <String, double?>{
      'subject': request.level == null || tutor.levels.contains(request.level)
          ? 1
          : 0.5,
      'schedule': request.slots.isEmpty
          ? null
          : scheduleCoverage(tutor.slots, request.slots),
      'distance': (1 - distance / request.radiusKm).clamp(0.0, 1.0),
      'price': request.budget == null
          ? null
          : priceScore(tutor.hourlyRate, request.budget!),
      'rating': bayesianRating(tutor.ratingAvg, tutor.ratingCount, systemMean),
    };
    final score = effective.entries.fold(
      0.0,
      (sum, e) => sum + e.value * components[e.key]!,
    );
    final reasons = <String>[
      if (tutor.levels.contains(request.level)) 'Khớp môn và cấp học mong muốn',
      if (request.slots.isNotEmpty)
        'Trùng ${tutor.slots.intersection(request.slots).length}/${request.slots.length} buổi bạn cần',
      'Cách ${distance.toStringAsFixed(1).replaceAll('.', ',')} km (gần đúng)',
      if (request.budget != null && tutor.hourlyRate <= request.budget!)
        'Học phí trong ngân sách',
      if (request.budget != null && tutor.hourlyRate > request.budget!)
        'Học phí vượt ngân sách',
      if (tutor.ratingCount > 0)
        'Đánh giá ${tutor.ratingAvg.toStringAsFixed(1).replaceAll('.', ',')} (${tutor.ratingCount} lượt)',
      if (tutor.ratingCount == 0) 'Chưa có đánh giá; dùng trung bình hệ thống',
    ];
    ranked.add(
      RankedTutor(
        tutor: tutor,
        score: score.clamp(0.0, 1.0),
        components: Map.unmodifiable(components),
        effectiveWeights: effective,
        distanceKm: distance,
        reasons: List.unmodifiable(reasons),
      ),
    );
  }
  ranked.sort((a, b) {
    if (mode == RankingMode.bestMatch) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
    }
    final d = a.distanceKm.compareTo(b.distanceKm);
    return d != 0 ? d : a.tutor.uid.compareTo(b.tutor.uid);
  });
  return RankingResult(ranked, skipped);
}
