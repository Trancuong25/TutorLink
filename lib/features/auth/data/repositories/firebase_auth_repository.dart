import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  @override
  Stream<AuthIdentity?> watchIdentity() => auth.userChanges().map(
    (user) => user == null
        ? null
        : AuthIdentity(user.uid, user.email ?? '', user.emailVerified),
  );
  @override
  Stream<AppUser?> watchProfile(String uid) =>
      db.collection('users').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return AppUser(
          uid: uid,
          email: data['email'] as String,
          displayName: data['displayName'] as String,
          role: UserRole.values.byName(data['role'] as String),
          isLocked: data['isLocked'] as bool,
        );
      });
  @override
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    if (role == UserRole.admin) throw ArgumentError('Không được tự tạo admin.');
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Nếu ghi hồ sơ thất bại, phiên Auth được giữ để hoàn tất ở lần tiếp theo.
    await completeProfile(name, role);
    await sendVerification();
  }

  @override
  Future<void> completeProfile(String name, UserRole role) async {
    if (role == UserRole.admin) throw ArgumentError('Vai trò không hợp lệ.');
    final user = auth.currentUser!;
    final ref = db.collection('users').doc(user.uid);
    await db.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, {
        'displayName': name.trim(),
        'email': user.email!,
        'role': role.name,
        'isLocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> sendVerification() => auth.currentUser!.sendEmailVerification();
  @override
  Future<void> reloadIdentity() async {
    await auth.currentUser?.reload();
  }

  @override
  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  @override
  Future<void> signOut() => auth.signOut();
}
