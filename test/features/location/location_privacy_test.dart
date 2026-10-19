import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/features/location/domain/location_point.dart';
import 'package:tutorlink/features/location/domain/location_privacy.dart';

void main() {
  test('10.000 mẫu lệch 200–500 m, khác gốc, ổn định theo UID và đầu vào', () {
    final random = Random(42);
    for (var i = 0; i < 10000; i++) {
      final p = LocationPoint(
        8 + random.nextDouble() * 16,
        102 + random.nextDouble() * 8,
      );
      final uid = 'uid_$i', a = blurLocation(uid, p), b = blurLocation(uid, p);
      expect(distanceMeters(p, a), inInclusiveRange(200, 500));
      expect(a.latitude, b.latitude);
      expect(a.longitude, b.longitude);
      expect(a.latitude == p.latitude && a.longitude == p.longitude, isFalse);
    }
  });
  test('biên địa lý, âm và đường đổi ngày', () {
    for (final lat in [-60.0, -11.0, 0.0, 60.0]) {
      for (final lon in [-180.0, -106.0, 0.0, 180.0]) {
        final p = LocationPoint(lat, lon);
        expect(
          distanceMeters(p, blurLocation('edge', p)),
          inInclusiveRange(200, 500),
        );
      }
    }
  });
  test('UID khác cho vị trí xấp xỉ khác và từ chối dữ liệu sai', () {
    const p = LocationPoint(10.9804, 106.6666);
    final points = {
      for (var i = 0; i < 20; i++)
        '${blurLocation('u$i', p).latitude},${blurLocation('u$i', p).longitude}',
    };
    expect(points.length, greaterThan(1));
    expect(() => blurLocation('', p), throwsArgumentError);
    expect(
      () => blurLocation('a', const LocationPoint(double.nan, 0)),
      throwsArgumentError,
    );
  });
  test('geohash chuẩn, chính xác 6 ký tự', () {
    expect(
      encodeGeohash(const LocationPoint(42.6, -5.6), precision: 5),
      'ezs42',
    );
    expect(encodeGeohash(const LocationPoint(10.9804, 106.6666)).length, 6);
  });
}
