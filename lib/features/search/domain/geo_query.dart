import 'dart:math' as math;

import '../../location/domain/location_point.dart';
import '../../location/domain/location_privacy.dart';

/// Phủ mọi ô giao với bounding box cầu, kể cả kinh tuyến ±180.
/// Khoảng cách Haversine được lọc lại sau truy vấn; geohash không phải hình tròn.
List<String> geohashCover(LocationPoint center, double radiusKm) {
  if (!center.isValid || radiusKm < 1 || radiusKm > 10 || !radiusKm.isFinite) {
    throw ArgumentError('Tâm hoặc bán kính không hợp lệ.');
  }
  final precision = radiusKm <= 2 ? 5 : 4;
  final bits = precision * 5;
  final latStep = 180 / math.pow(2, bits ~/ 2);
  final lonStep = 360 / math.pow(2, (bits + 1) ~/ 2);
  final angular = radiusKm * 1000 / 6371000;
  final latDelta = angular * 180 / math.pi;
  final lonDelta =
      math.asin(math.sin(angular) / math.cos(center.latitude * math.pi / 180)) *
      180 /
      math.pi;
  final minY = ((center.latitude - latDelta + 90) / latStep).floor();
  final maxY = ((center.latitude + latDelta + 90) / latStep).floor();
  final minX = ((center.longitude - lonDelta + 180) / lonStep).floor();
  final maxX = ((center.longitude + lonDelta + 180) / lonStep).floor();
  final result = <String>{};
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      // encodeGeohash hiện hỗ trợ ±60°; tâm ô có thể vượt 60° ở biên.
      final lat = (-90 + (y + 0.5) * latStep).clamp(-60.0, 60.0);
      final lon = ((-180 + (x + 0.5) * lonStep) + 180) % 360 - 180;
      result.add(encodeGeohash(LocationPoint(lat, lon), precision: precision));
    }
  }
  return result.toList()..sort();
}
