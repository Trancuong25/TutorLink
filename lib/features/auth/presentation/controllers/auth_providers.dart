import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    FirebaseAuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);

final identityProvider = StreamProvider<AuthIdentity?>(
  (ref) => ref.watch(authRepositoryProvider).watchIdentity(),
);
final profileProvider = StreamProvider.family<AppUser?, String>(
  (ref, uid) => ref.watch(authRepositoryProvider).watchProfile(uid),
);
