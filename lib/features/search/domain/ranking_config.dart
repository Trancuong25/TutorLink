import 'package:tutor_ranking/tutor_ranking.dart';

class RankingConfig {
  const RankingConfig(this.weights, this.systemMean);
  final RankingWeights weights;
  final double systemMean;
  factory RankingConfig.parse(Map<String, dynamic> data) {
    final values = {
      for (final key in RankingWeights.keys) key: (data[key] as num).toDouble(),
    };
    final mean = (data['systemRatingMean'] as num).toDouble();
    if (!mean.isFinite || mean < 0 || mean > 5) {
      throw ArgumentError('Trung bình hệ thống phải từ 0 đến 5.');
    }
    return RankingConfig(RankingWeights(values), mean);
  }
}

class RankingConfiguration {
  const RankingConfiguration(this.current, this.fallback, {this.warning});
  final RankingConfig current, fallback;
  final String? warning;
  factory RankingConfiguration.resolve(
    Map<String, dynamic>? remote,
    RankingConfig fallback,
  ) {
    try {
      if (remote == null) throw StateError('Thiếu cấu hình');
      return RankingConfiguration(RankingConfig.parse(remote), fallback);
    } catch (_) {
      return RankingConfiguration(
        fallback,
        fallback,
        warning: 'Trọng số hoặc trung bình hệ thống thiếu/sai. Đang dùng cấu hình mặc định.',
      );
    }
  }
}
