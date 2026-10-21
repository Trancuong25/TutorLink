import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_ranking/tutor_ranking.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutorlink/features/location/domain/location_point.dart';
import 'package:tutorlink/features/location/presentation/location_providers.dart';
import 'package:tutorlink/features/search/domain/ranking_config.dart';
import 'package:tutorlink/features/search/domain/search_models.dart';
import 'package:tutorlink/features/search/presentation/ranking_providers.dart';
import 'package:tutorlink/features/search/presentation/search_page.dart';
import 'package:tutorlink/features/search/presentation/search_providers.dart';
import 'package:tutorlink/features/search/presentation/tutor_search_card.dart';
import 'package:tutorlink/features/tutor_profile/domain/tutor_profile.dart';

class FixedLocation extends SearchLocation {
  @override
  LocationSelection? build() => const LocationSelection(
    LocationPoint(10.98, 106.66),
    'manual',
    'Khu vực thử',
  );
}

class FixedFilters extends SearchFilters {
  @override
  SearchRequest build() =>
      const SearchRequest(level: 'high', budget: 100000, slots: {0});
}

void main() {
  test('Haversine tìm kiếm và ranking giống hệt ở biên bán kính', () {
    for (final p in [
      const LocationPoint(0, .01),
      const LocationPoint(10.98, 106.66),
      const LocationPoint(60, 179.99),
    ]) {
      const center = LocationPoint(10.9804, 106.6666);
      expect(
        distanceMeters(center, p) / 1000,
        haversineKm(
          Position(center.latitude, center.longitude),
          Position(p.latitude, p.longitude),
        ),
      );
    }
  });
  final fallback = RankingConfig.parse(
    jsonDecode(File('config/ranking_defaults.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  test('cấu hình sai/thiếu dùng mặc định và báo cảnh báo', () {
    for (final data in [
      null,
      {'subject': -1},
      {...fallback.weights.values, 'systemRatingMean': double.nan},
    ]) {
      final c = RankingConfiguration.resolve(data, fallback);
      expect(c.current, same(fallback));
      expect(c.warning, isNotNull);
    }
  });
  testWidgets(
    'đổi chế độ đổi thứ tự, giải thích thật, không tải lại ứng viên',
    (tester) async {
      const near = TutorProfile(
        uid: 'near',
        displayName: 'Gia sư gần',
        bio: '',
        subjects: ['math'],
        levels: ['primary'],
        hourlyRate: 500000,
        availability: {5},
        approxLocation: LocationPoint(10.98, 106.66),
      );
      const fit = TutorProfile(
        uid: 'fit',
        displayName: 'Gia sư hợp',
        bio: '',
        subjects: ['math'],
        levels: ['high'],
        hourlyRate: 100000,
        availability: {0},
        approxLocation: LocationPoint(10.989, 106.66),
      );
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            identityProvider.overrideWith((ref) => Stream.value(null)),
            searchLocationProvider.overrideWith(FixedLocation.new),
            searchFiltersProvider.overrideWith(FixedFilters.new),
            rankingConfigurationProvider.overrideWith(
              (ref) => Stream.value(RankingConfiguration(fallback, fallback)),
            ),
            searchResultsProvider.overrideWith((ref) async {
              calls++;
              return const SearchResult([
                SearchHit(near, 0),
                SearchHit(fit, 1),
              ]);
            }),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TutorSearchCard>(find.byType(TutorSearchCard).first)
            .hit
            .tutor
            .uid,
        'near',
      );
      expect(find.textContaining('Vì sao phù hợp'), findsNothing);
      await tester.tap(find.text('Phù hợp nhất'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TutorSearchCard>(find.byType(TutorSearchCard).first)
            .hit
            .tutor
            .uid,
        'fit',
      );
      expect(find.textContaining('Trùng 1/1 buổi'), findsOneWidget);
      expect(find.textContaining('Vì sao phù hợp'), findsWidgets);
      await tester.tap(find.text('Gần nhất'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Vì sao phù hợp'), findsNothing);
      expect(calls, 1);
    },
  );
}
