import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tutorlink/features/auth/domain/entities/app_user.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutorlink/features/tutor_profile/domain/tutor_profile.dart';
import 'package:tutorlink/features/tutor_profile/domain/tutor_repository.dart';
import 'package:tutorlink/features/tutor_profile/presentation/tutor_editor_page.dart';
import 'package:tutorlink/features/tutor_profile/presentation/tutor_detail_page.dart';
import 'package:tutorlink/features/tutor_profile/presentation/tutor_providers.dart';

class MockTutorRepository extends Mock implements TutorRepository {}

const tutor = TutorProfile(
  uid: 't',
  displayName: 'Cô An',
  bio: 'Dạy Toán',
  subjects: ['math'],
  levels: ['high'],
  hourlyRate: 150000,
  availability: {2, 5},
);
void main() {
  testWidgets('xem hồ sơ read-only và không có yêu cầu học', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorProfileProvider('t').overrideWith((ref) => Stream.value(tutor)),
        ],
        child: const MaterialApp(home: TutorDetailPage(uid: 't')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cô An'), findsOneWidget);
    expect(find.text('Chưa chia sẻ khu vực.'), findsOneWidget);
    expect(find.text('Gửi yêu cầu'), findsNothing);
  });
  testWidgets('sửa hồ sơ có lưới 21 ô, lưu qua repository', (tester) async {
    final repo = MockTutorRepository();
    registerFallbackValue(tutor);
    when(() => repo.save(any())).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityProvider.overrideWith(
            (ref) =>
                Stream.value(const AuthIdentity('t', 't@example.com', true)),
          ),
          tutorProfileProvider('t').overrideWith((ref) => Stream.value(tutor)),
          tutorRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: TutorEditorPage()),
      ),
    );
    await tester.pumpAndSettle();
    // Cuộn đến nút để kiểm tra form trong viewport điện thoại.
    await tester.scrollUntilVisible(
      find.text('Lưu hồ sơ'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.save(captureAny())).captured.single as TutorProfile;
    expect(saved.availability, {2, 5});
    expect(saved.subjects, ['math']);
    expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
  });
}
