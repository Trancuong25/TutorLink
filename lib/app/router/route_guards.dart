import '../../features/auth/domain/entities/app_user.dart';

enum SessionStatus {
  loading,
  signedOut,
  missingProfile,
  unverified,
  ready,
  locked,
  error,
}

class Session {
  const Session(this.status, [this.role]);
  final SessionStatus status;
  final UserRole? role;
}

String homePath(UserRole role) => '/${role.name}';
String? routeRedirect(Session session, String location) {
  final target = switch (session.status) {
    SessionStatus.loading => '/loading',
    SessionStatus.signedOut => '/login',
    SessionStatus.missingProfile => '/complete-profile',
    SessionStatus.unverified => '/verify-email',
    SessionStatus.locked => '/locked',
    SessionStatus.error => '/session-error',
    SessionStatus.ready => homePath(session.role!),
  };
  if (session.status == SessionStatus.signedOut &&
      ['/login', '/register', '/forgot-password'].contains(location)) {
    return null;
  }
  // GĐ1 mỗi vai trò có một trang chủ; deep link sai vai trò bị chuyển về trang đúng.
  return location == target ? null : target;
}
