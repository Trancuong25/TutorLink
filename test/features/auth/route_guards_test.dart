import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/app/router/route_guards.dart';
import 'package:tutorlink/features/auth/domain/entities/app_user.dart';

void main() {
  test('khách chỉ vào các màn hình xác thực', () {
    for (final path in ['/login', '/register', '/forgot-password']) {
      expect(
        routeRedirect(const Session(SessionStatus.signedOut), path),
        isNull,
      );
    }
    expect(
      routeRedirect(const Session(SessionStatus.signedOut), '/admin'),
      '/login',
    );
  });
  for (final role in UserRole.values) {
    test('đúng quyền ${role.name}, chặn deep link khác vai trò', () {
      final session = Session(SessionStatus.ready, role);
      expect(routeRedirect(session, homePath(role)), isNull);
      for (final other in UserRole.values.where((r) => r != role)) {
        expect(routeRedirect(session, homePath(other)), homePath(role));
      }
      expect(routeRedirect(session, '/login'), homePath(role));
    });
    test('khóa ưu tiên ở mọi vai trò ${role.name}', () {
      expect(
        routeRedirect(Session(SessionStatus.locked, role), homePath(role)),
        '/locked',
      );
      expect(
        routeRedirect(Session(SessionStatus.locked, role), '/locked'),
        isNull,
      );
    });
  }
  for (final entry in {
    SessionStatus.loading: '/loading',
    SessionStatus.error: '/session-error',
    SessionStatus.missingProfile: '/complete-profile',
    SessionStatus.unverified: '/verify-email',
  }.entries) {
    test('điều hướng ${entry.key.name}', () {
      expect(routeRedirect(Session(entry.key), '/admin'), entry.value);
      expect(routeRedirect(Session(entry.key), entry.value), isNull);
    });
  }
}
