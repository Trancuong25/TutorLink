enum UserRole {
  learner('Người học'),
  tutor('Gia sư'),
  admin('Quản trị viên');

  const UserRole(this.label);
  final String label;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isLocked,
  });
  final String uid, email, displayName;
  final UserRole role;
  final bool isLocked;
}

class AuthIdentity {
  const AuthIdentity(this.uid, this.email, this.emailVerified);
  final String uid, email;
  final bool emailVerified;
}
