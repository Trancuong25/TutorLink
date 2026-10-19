import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/controllers/auth_providers.dart';
import '../data/device_location_service.dart';
import '../domain/location_point.dart';

final deviceLocationProvider = Provider((ref) => DeviceLocationService());

class SearchLocation extends Notifier<LocationSelection?> {
  @override
  LocationSelection? build() {
    // Vị trí tìm kiếm chỉ trong RAM, xóa khi tài khoản thay đổi.
    ref.watch(identityProvider.select((v) => v.asData?.value?.uid));
    return null;
  }

  void select(LocationSelection? value) => state = value;
}

final searchLocationProvider =
    NotifierProvider<SearchLocation, LocationSelection?>(SearchLocation.new);
