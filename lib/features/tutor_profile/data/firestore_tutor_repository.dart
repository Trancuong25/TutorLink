import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/tutor_profile.dart';
import '../domain/tutor_repository.dart';
import '../../location/domain/location_point.dart';
import '../../location/domain/location_privacy.dart';

class FirestoreTutorRepository implements TutorRepository {
  FirestoreTutorRepository(this.db);
  final FirebaseFirestore db;
  TutorProfile _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final p = d['approxLocation'] as GeoPoint?;
    return TutorProfile(
      uid: doc.id,
      displayName: d['displayName'] as String,
      bio: d['bio'] as String,
      subjects: List<String>.from(d['subjects'] as List),
      levels: List<String>.from(d['levels'] as List),
      hourlyRate: d['hourlyRate'] as int,
      availability: Set<int>.from(d['availability'] as List),
      teachingMode: d['teachingMode'] as String,
      isAvailable: d['isAvailable'] as bool,
      approxLocation: p == null ? null : LocationPoint(p.latitude, p.longitude),
      geohash: d['geohash'] as String?,
      ratingAvg: (d['ratingAvg'] as num).toDouble(),
      ratingCount: d['ratingCount'] as int,
      isMock: d['isMock'] as bool,
      isHidden: d['isHidden'] as bool,
    );
  }

  @override
  Stream<TutorProfile?> watch(String uid) => db
      .collection('tutors')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? _decode(doc) : null);
  @override
  Future<List<TutorProfile>> list() async {
    final snapshot = await db
        .collection('tutors')
        .where('isHidden', isEqualTo: false)
        .limit(150)
        .get();
    return snapshot.docs.map(_decode).toList();
  }

  @override
  Future<void> save(TutorProfile p) async {
    final error = p.validate();
    if (error != null) throw ArgumentError(error);
    final ref = db.collection('tutors').doc(p.uid);
    await db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final data = <String, dynamic>{
        'displayName': p.displayName.trim(),
        'bio': p.bio.trim(),
        'subjects': p.subjects,
        'levels': p.levels,
        'hourlyRate': p.hourlyRate,
        'availability': p.availability.toList()..sort(),
        'teachingMode': p.teachingMode,
        'isAvailable': p.isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Không ghi đè rating, trạng thái ẩn hoặc vị trí khi sửa thông tin.
      if (!existing.exists) {
        data.addAll({
          'approxLocation': null,
          'geohash': null,
          'ratingAvg': 0.0,
          'ratingCount': 0,
          'isMock': false,
          'isHidden': false,
        });
      }
      tx.set(ref, data, SetOptions(merge: true));
    });
  }

  @override
  Future<void> saveLocation(String uid, LocationSelection selection) async {
    final approx = blurLocation(uid, selection.point);
    final batch = db.batch();
    batch.set(db.collection('private_locations').doc(uid), {
      'location': GeoPoint(selection.point.latitude, selection.point.longitude),
      'source': selection.source,
      'consentVersion': 'location-v1',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(db.collection('tutors').doc(uid), {
      'approxLocation': GeoPoint(approx.latitude, approx.longitude),
      'geohash': encodeGeohash(approx),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> revokeLocation(String uid) async {
    final batch = db.batch();
    batch.delete(db.collection('private_locations').doc(uid));
    batch.update(db.collection('tutors').doc(uid), {
      'approxLocation': null,
      'geohash': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
