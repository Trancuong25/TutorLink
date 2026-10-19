import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tutorlink/features/auth/domain/entities/app_user.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutorlink/features/location/data/device_location_service.dart';
import 'package:tutorlink/features/location/presentation/location_page.dart';
import 'package:tutorlink/features/location/presentation/location_providers.dart';

class MockDeviceLocation extends Mock implements DeviceLocationService {}

void main() {
  testWidgets('từ chối GPS vẫn chọn tâm thủ công, chỉ lưu trong RAM', (
    tester,
  ) async {
    final device = MockDeviceLocation();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceLocationProvider.overrideWithValue(device),
          identityProvider.overrideWith(
            (ref) =>
                Stream.value(const AuthIdentity('l', 'l@example.com', true)),
          ),
          profileProvider('l').overrideWith(
            (ref) => Stream.value(
              const AppUser(
                uid: 'l',
                email: 'l@example.com',
                displayName: 'An',
                role: UserRole.learner,
                isLocked: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: LocationPage(isTutor: false)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Từ chối GPS — nhập khu vực'));
    await tester.tap(find.text('Từ chối GPS — nhập khu vực'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Chọn tâm Phú Lợi, TP.HCM'));
    await tester.tap(find.text('Chọn tâm Phú Lợi, TP.HCM'));
    await tester.pump();
    await tester.ensureVisible(find.text('Dùng khu vực này'));
    await tester.tap(find.text('Dùng khu vực này'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LocationPage)),
    );
    expect(container.read(searchLocationProvider)?.point.latitude, 10.9804);
    verifyNever(() => device.requestOnce());
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa vị trí / Thu hồi đồng ý'));
    await tester.pumpAndSettle();
    expect(container.read(searchLocationProvider), isNull);
  });
}
