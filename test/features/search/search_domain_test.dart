import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/features/location/domain/location_point.dart';
import 'package:tutorlink/features/location/domain/location_privacy.dart';
import 'package:tutorlink/features/search/domain/geo_query.dart';
import 'package:tutorlink/features/search/domain/search_models.dart';
import 'package:tutorlink/features/tutor_profile/domain/tutor_profile.dart';

void main() {
  test(
    'Haversine zero, đối xứng, qua kinh tuyến ngày và khoảng cách đã biết',
    () {
      const a = LocationPoint(0, 0), b = LocationPoint(0, 1);
      expect(distanceMeters(a, a), 0);
      expect(distanceMeters(a, b), closeTo(111194.93, 0.1));
      expect(distanceMeters(a, b), distanceMeters(b, a));
      expect(
        distanceMeters(
          const LocationPoint(0, 179.99),
          const LocationPoint(0, -179.99),
        ),
        lessThan(2230),
      );
    },
  );
  test('cover chứa mọi điểm trong vòng tròn, ô lân cận và biên ±180', () {
    final random = Random(42);
    for (final center in [
      const LocationPoint(10.9804, 106.6666),
      const LocationPoint(0, 0),
      const LocationPoint(59.8, 179.99),
      const LocationPoint(-59.8, -179.99),
    ]) {
      for (final radius in [1.0, 2.0, 3.0, 10.0]) {
        final cover = geohashCover(center, radius);
        for (var i = 0; i < 2000; i++) {
          final lat =
              center.latitude + (random.nextDouble() * 2 - 1) * radius / 110;
          final lon =
              (center.longitude +
                      (random.nextDouble() * 2 - 1) *
                          radius /
                          (110 * cos(center.latitude * pi / 180)) +
                      180) %
                  360 -
              180;
          final p = LocationPoint(lat, lon);
          if (distanceMeters(center, p) <= radius * 1000) {
            expect(
              cover,
              contains(encodeGeohash(p, precision: cover.first.length)),
            );
          }
        }
      }
    }
    expect(
      () => geohashCover(const LocationPoint(0, 0), 0),
      throwsArgumentError,
    );
  });
  const center = LocationPoint(10.98, 106.66);
  const tutor = TutorProfile(
    uid: 'a',
    displayName: 'A',
    bio: '',
    subjects: ['math'],
    levels: ['high'],
    hourlyRate: 150000,
    availability: {0, 2, 5},
    approxLocation: center,
    teachingMode: 'both',
  );
  test('môn/bán kính bắt buộc, các mong muốn chỉ lọc khi bật', () {
    expect(
      const SearchRequest(subject: 'english').matches(tutor, center),
      false,
    );
    expect(
      const SearchRequest(
        level: 'primary',
        budget: 100000,
        slots: {3},
      ).matches(tutor, center),
      true,
    );
    expect(
      const SearchRequest(
        level: 'primary',
        requireLevel: true,
      ).matches(tutor, center),
      false,
    );
    expect(
      const SearchRequest(
        budget: 100000,
        requireBudget: true,
      ).matches(tutor, center),
      false,
    );
    expect(
      const SearchRequest(
        slots: {0, 2},
        requireSchedule: true,
      ).matches(tutor, center),
      true,
    );
    expect(
      const SearchRequest(
        slots: {0, 3},
        requireSchedule: true,
      ).matches(tutor, center),
      false,
    );
    expect(const SearchRequest(mode: 'online').matches(tutor, center), true);
    expect(
      const SearchRequest().matches(tutor, const LocationPoint(11.98, 106.66)),
      false,
    );
  });
}
