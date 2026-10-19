import 'package:geolocator/geolocator.dart';

import '../domain/location_point.dart';

class DeviceLocationService {
  Future<LocationSelection> requestOnce() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Hãy bật dịch vụ vị trí hoặc nhập khu vực thủ công.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Bạn chưa cấp quyền vị trí. Vẫn có thể nhập khu vực thủ công.',
      );
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LocationSelection(
      LocationPoint(p.latitude, p.longitude),
      'gps',
      'Vị trí thiết bị',
    );
  }
}
