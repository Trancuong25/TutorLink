import 'dart:math' as math;

import 'location_point.dart';

// Đây là giảm độ chính xác, không phải mã hóa hoặc bảo đảm ẩn danh.
LocationPoint blurLocation(String uid, LocationPoint exact) {
  if (uid.isEmpty || !exact.isValid) {
    throw ArgumentError('Vị trí/UID không hợp lệ.');
  }
  var hash = 2166136261;
  for (final c in uid.codeUnits) {
    hash = ((hash ^ c) * 16777619) & 0xffffffff;
  }
  final jitterX = (hash % 81) - 40.0;
  final jitterY = ((hash ~/ 81) % 81) - 40.0;
  const meterLat = 6371000 * math.pi / 180;
  final meterLon = meterLat * math.cos(11 * math.pi / 180);
  final gx = (exact.longitude * meterLon / 400).round();
  final gy = (exact.latitude * meterLat / 400).round();
  final candidates = <LocationPoint>[];
  for (var x = -4; x <= 4; x++) {
    for (var y = -2; y <= 2; y++) {
      final lon = ((gx + x) * 400 + jitterX) / meterLon;
      final wrapped = (lon + 180) % 360 - 180;
      final p = LocationPoint(((gy + y) * 400 + jitterY) / meterLat, wrapped);
      final d = distanceMeters(exact, p);
      if (p.isValid && d >= 200 && d <= 500) candidates.add(p);
    }
  }
  if (candidates.isEmpty) throw StateError('Không tìm thấy ô làm mờ phù hợp.');
  // Chọn từ các tâm lưới: không cộng vector có thể đảo ngược trực tiếp vào GPS.
  return candidates[hash % candidates.length];
}

String encodeGeohash(LocationPoint point, {int precision = 6}) {
  if (!point.isValid || precision < 1 || precision > 12) {
    throw ArgumentError('Geohash không hợp lệ.');
  }
  const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
  var latMin = -90.0, latMax = 90.0, lonMin = -180.0, lonMax = 180.0;
  var even = true, bits = 0, value = 0;
  final result = StringBuffer();
  while (result.length < precision) {
    final mid = even ? (lonMin + lonMax) / 2 : (latMin + latMax) / 2;
    final high = (even ? point.longitude : point.latitude) >= mid;
    value = (value << 1) | (high ? 1 : 0);
    if (even) {
      if (high) {
        lonMin = mid;
      } else {
        lonMax = mid;
      }
    } else {
      if (high) {
        latMin = mid;
      } else {
        latMax = mid;
      }
    }
    even = !even;
    if (++bits == 5) {
      result.write(alphabet[value]);
      bits = 0;
      value = 0;
    }
  }
  return result.toString();
}
