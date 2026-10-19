import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/controllers/auth_providers.dart';
import '../data/firestore_tutor_repository.dart';
import '../domain/tutor_profile.dart';
import '../domain/tutor_repository.dart';

final tutorRepositoryProvider = Provider<TutorRepository>(
  (ref) => FirestoreTutorRepository(FirebaseFirestore.instance),
);
final tutorProfileProvider = StreamProvider.autoDispose
    .family<TutorProfile?, String>((ref, uid) {
      ref.watch(identityProvider);
      return ref.watch(tutorRepositoryProvider).watch(uid);
    });
final tutorDirectoryProvider = FutureProvider.autoDispose<List<TutorProfile>>((
  ref,
) {
  ref.watch(identityProvider);
  return ref.watch(tutorRepositoryProvider).list();
});
