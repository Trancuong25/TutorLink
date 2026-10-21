import '../../location/domain/location_point.dart';
import '../../tutor_profile/domain/tutor_profile.dart';

class SearchRequest {
  const SearchRequest({
    this.subject = 'math',
    this.level,
    this.budget,
    this.slots = const {},
    this.radiusKm = 5,
    this.mode,
    this.requireLevel = false,
    this.requireBudget = false,
    this.requireSchedule = false,
  });
  final String subject;
  final String? level, mode;
  final int? budget;
  final Set<int> slots;
  final double radiusKm;
  final bool requireLevel, requireBudget, requireSchedule;

  bool matches(TutorProfile tutor, LocationPoint center) {
    final p = tutor.approxLocation;
    return !tutor.isHidden &&
        tutor.isAvailable &&
        p != null &&
        tutor.subjects.contains(subject) &&
        distanceMeters(center, p) <= radiusKm * 1000 + 0.001 &&
        (!requireLevel || level == null || tutor.levels.contains(level)) &&
        (!requireBudget || budget == null || tutor.hourlyRate <= budget!) &&
        (!requireSchedule ||
            slots.isEmpty ||
            tutor.availability.containsAll(slots)) &&
        (mode == null ||
            tutor.teachingMode == mode ||
            tutor.teachingMode == 'both');
  }
}

class SearchHit {
  const SearchHit(this.tutor, this.distanceKm);
  final TutorProfile tutor;
  final double distanceKm;
}

class SearchResult {
  const SearchResult(
    this.hits, {
    this.elapsed = Duration.zero,
    this.truncated = false,
  });
  final List<SearchHit> hits;
  final Duration elapsed;
  final bool truncated;
}

abstract interface class SearchRepository {
  Future<SearchResult> search(LocationPoint center, SearchRequest request);
}
