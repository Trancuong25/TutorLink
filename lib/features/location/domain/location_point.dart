import 'dart:math' as math;

class LocationPoint {
  const LocationPoint(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 60 &&
      longitude.abs() <= 180;
}

double distanceMeters(LocationPoint a, LocationPoint b) {
  const r = 6371000.0;
  final lat = (b.latitude - a.latitude) * math.pi / 180;
  final lon = (b.longitude - a.longitude) * math.pi / 180;
  final h =
      math.pow(math.sin(lat / 2), 2) +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          math.pow(math.sin(lon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h.clamp(0, 1)));
}

class LocationSelection {
  const LocationSelection(this.point, this.source, this.label);
  final LocationPoint point;
  final String source, label;
}
