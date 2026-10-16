import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tutorlink/features/auth/domain/repositories/auth_repository.dart';
import 'package:tutorlink/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutorlink/features/auth/presentation/pages/auth_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  setUp(() {
    repo = MockAuthRepository();
  });
  Future<void> pump(
    WidgetTester tester, [
    AuthPageMode mode = AuthPageMode.login,
  ]) => tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: AuthPage(mode: mode)),
    ),
  );
  testWidgets('hiện đăng nhập, đăng ký, quên mật khẩu', (tester) async {
    await pump(tester);
    expect(find.text('TutorLink'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
  });
  testWidgets('dữ liệu sai không gọi backend', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Nhập mật khẩu.'), findsOneWidget);
    verifyNever(() => repo.signIn(any(), any()));
  });
  testWidgets('loading chặn gửi lặp, hiển thị lỗi và thử lại được', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(() => repo.signIn(any(), any())).thenAnswer((_) => completer.future);
    await pump(tester);
    await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'password123');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('submit'))).onPressed,
      isNull,
    );
    completer.completeError(Exception('failed'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không thể hoàn tất thao tác. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('submit'))).onPressed,
      isNotNull,
    );
    verify(() => repo.signIn('test@example.com', 'password123')).called(1);
  });
  testWidgets('quên mật khẩu gửi email và thông báo trung tính', (
    tester,
  ) async {
    when(() => repo.resetPassword(any())).thenAnswer((_) async {});
    await pump(tester, AuthPageMode.forgotPassword);
    await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    verify(() => repo.resetPassword('test@example.com')).called(1);
    expect(find.textContaining('Nếu email đã được đăng ký'), findsOneWidget);
  });
}
