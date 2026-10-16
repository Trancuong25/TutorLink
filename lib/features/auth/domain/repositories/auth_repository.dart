import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AuthIdentity?> watchIdentity();
  Stream<AppUser?> watchProfile(String uid);
  Future<void> signIn(String email, String password);
  Future<void> register(
    String name,
    String email,
    String password,
    UserRole role,
  );
  Future<void> completeProfile(String name, UserRole role);
  Future<void> sendVerification();
  Future<void> reloadIdentity();
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
