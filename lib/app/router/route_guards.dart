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
  if (session.status == SessionStatus.locked &&
      session.role == UserRole.tutor &&
      location == '/location') {
    return null;
  }
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
  if (session.status == SessionStatus.ready) {
    if (location == '/search' && session.role == UserRole.learner) return null;
    if (location == '/tutors' ||
        RegExp(r'^/tutors/[^/]+$').hasMatch(location)) {
      return null;
    }
    if (location == '/tutor/profile' && session.role == UserRole.tutor) {
      return null;
    }
    if (location == '/location' && session.role != UserRole.admin) return null;
  }
  return location == target ? null : target;
}
