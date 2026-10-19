import '../../../core/constants/tutor_catalog.dart' as catalog;
import '../../location/domain/location_point.dart';

class TutorProfile {
  const TutorProfile({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.subjects,
    required this.levels,
    required this.hourlyRate,
    required this.availability,
    this.teachingMode = 'both',
    this.isAvailable = true,
    this.approxLocation,
    this.geohash,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isMock = false,
    this.isHidden = false,
  });
  final String uid, displayName, bio, teachingMode;
  final List<String> subjects, levels;
  final int hourlyRate, ratingCount;
  final Set<int> availability;
  final bool isAvailable, isMock, isHidden;
  final double ratingAvg;
  final LocationPoint? approxLocation;
  final String? geohash;

  String? validate() {
    if (displayName.trim().isEmpty || displayName.trim().length > 80) {
      return 'Tên phải có 1–80 ký tự.';
    }
    if (bio.trim().length > 2000) return 'Giới thiệu tối đa 2.000 ký tự.';
    if (subjects.isEmpty ||
        subjects.any((s) => !catalog.subjects.containsKey(s)) ||
        subjects.toSet().length != subjects.length) {
      return 'Chọn ít nhất một môn hợp lệ.';
    }
    if (levels.isEmpty ||
        levels.any((s) => !catalog.levels.containsKey(s)) ||
        levels.toSet().length != levels.length) {
      return 'Chọn ít nhất một cấp học hợp lệ.';
    }
    if (hourlyRate < 50000 || hourlyRate > 1000000) {
      return 'Học phí từ 50.000 đến 1.000.000 đồng/giờ.';
    }
    if (availability.isEmpty || availability.any((s) => s < 0 || s > 20)) {
      return 'Chọn ít nhất một buổi rảnh.';
    }
    if (!catalog.teachingModes.containsKey(teachingMode)) {
      return 'Chọn hình thức dạy hợp lệ.';
    }
    return null;
  }
}
