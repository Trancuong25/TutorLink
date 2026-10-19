import 'package:flutter_test/flutter_test.dart';
import 'package:tutorlink/app/router/route_guards.dart';
import 'package:tutorlink/features/auth/domain/entities/app_user.dart';

void main() {
  test('chỉ tutor sửa hồ sơ; mọi vai trò hoạt động xem hồ sơ', () {
    for (final role in UserRole.values) {
      final session = Session(SessionStatus.ready, role);
      expect(routeRedirect(session, '/tutors/mock_001'), isNull);
      expect(
        routeRedirect(session, '/tutor/profile'),
        role == UserRole.tutor ? null : homePath(role),
      );
    }
    expect(
      routeRedirect(const Session(SessionStatus.signedOut), '/tutors/mock_001'),
      '/login',
    );
  });
  test('tutor khóa vẫn thu hồi vị trí, không sửa hồ sơ', () {
    const s = Session(SessionStatus.locked, UserRole.tutor);
    expect(routeRedirect(s, '/location'), isNull);
    expect(routeRedirect(s, '/tutor/profile'), '/locked');
  });
}
