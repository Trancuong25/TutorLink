import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../location/domain/location_point.dart';
import '../../tutor_profile/data/firestore_tutor_repository.dart';
import '../domain/geo_query.dart';
import '../domain/search_models.dart';

class FirestoreSearchRepository implements SearchRepository {
  FirestoreSearchRepository(this.db);
  final FirebaseFirestore db;

  @override
  Future<SearchResult> search(
    LocationPoint center,
    SearchRequest request,
  ) async {
    final timer = Stopwatch()..start();
    final prefixes = geohashCover(center, request.radiusKm);
    // Mỗi range tối đa 100 bản ghi. Chỉ đọc collection công khai.
    final snapshots = await Future.wait(
      prefixes.map(
        (prefix) => db
            .collection('tutors')
            .where('isHidden', isEqualTo: false)
            .where('isAvailable', isEqualTo: true)
            .where('subjects', arrayContains: request.subject)
            .orderBy('geohash')
            .startAt([prefix])
            .endAt(['$prefix~'])
            .limit(100)
            .get(const GetOptions(source: Source.server)),
      ),
    );
    final docs = {
      for (final s in snapshots)
        for (final d in s.docs) d.id: d,
    };
    final hits =
        docs.values
            .map(FirestoreTutorRepository.decode)
            .where((t) => request.matches(t, center))
            .map(
              (t) => SearchHit(
                t,
                distanceMeters(center, t.approxLocation!) / 1000,
              ),
            )
            .toList()
          ..sort((a, b) {
            final d = a.distanceKm.compareTo(b.distanceKm);
            return d != 0 ? d : a.tutor.uid.compareTo(b.tutor.uid);
          });
    timer.stop();
    if (kDebugMode) {
      debugPrint(
        'TutorLink search: ${timer.elapsedMilliseconds}ms, '
        '${prefixes.length} ranges, ${docs.length} public docs, ${hits.length} matches',
      );
    }
    return SearchResult(
      hits.take(100).toList(),
      elapsed: timer.elapsed,
      truncated:
          hits.length > 100 || snapshots.any((s) => s.docs.length == 100),
    );
  }
}
