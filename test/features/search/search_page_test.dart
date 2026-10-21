import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutorlink/features/location/domain/location_point.dart';
import 'package:tutorlink/features/location/presentation/location_providers.dart';
import 'package:tutorlink/features/search/domain/search_models.dart';
import 'package:tutorlink/features/search/presentation/search_page.dart';
import 'package:tutorlink/features/search/presentation/search_providers.dart';
import 'package:tutorlink/features/tutor_profile/domain/tutor_profile.dart';

class TestLocation extends SearchLocation {
  @override
  LocationSelection? build() => const LocationSelection(
    LocationPoint(10.98, 106.66),
    'manual',
    'Phú Lợi',
  );
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    Future<SearchResult> Function() fetch,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityProvider.overrideWith((ref) => Stream.value(null)),
          searchLocationProvider.overrideWith(TestLocation.new),
          searchResultsProvider.overrideWith((ref) => fetch()),
        ],
        child: const MaterialApp(home: SearchPage()),
      ),
    );
  }

  testWidgets('loading', (tester) async {
    final pending = Completer<SearchResult>();
    await mount(tester, () => pending.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const SearchResult([]));
    await tester.pumpAndSettle();
  });
  testWidgets('rỗng và lỗi có nút thử lại', (tester) async {
    await mount(tester, () => Future.value(const SearchResult([])));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hãy tăng bán kính'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await mount(tester, () => Future.error(StateError('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
  });
  testWidgets('dữ liệu và chuyển bản đồ không mất bộ lọc', (tester) async {
    const t = TutorProfile(
      uid: 'a',
      displayName: 'Cô An',
      bio: '',
      subjects: ['math'],
      levels: ['high'],
      hourlyRate: 150000,
      availability: {0},
      approxLocation: LocationPoint(10.98, 106.66),
    );
    await mount(
      tester,
      () => Future.value(const SearchResult([SearchHit(t, 1.2)])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cô An'), findsOneWidget);
    expect(find.textContaining('1,2 km (gần đúng)'), findsOneWidget);
    await tester.tap(find.text('Bản đồ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa cấu hình bản đồ'), findsOneWidget);
    await tester.tap(find.text('Danh sách'));
    await tester.pumpAndSettle();
    expect(find.text('Cô An'), findsOneWidget);
  });
}
