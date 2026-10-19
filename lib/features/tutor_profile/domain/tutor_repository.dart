import 'tutor_profile.dart';
import '../../location/domain/location_point.dart';

abstract interface class TutorRepository {
  Stream<TutorProfile?> watch(String uid);
  Future<List<TutorProfile>> list();
  Future<void> save(TutorProfile profile);
  Future<void> saveLocation(String uid, LocationSelection selection);
  Future<void> revokeLocation(String uid);
}
