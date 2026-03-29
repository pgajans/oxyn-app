import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/device_repository.dart';
import 'device_info_model.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository();
});

final deviceInfoProvider =
    AsyncNotifierProvider<DeviceInfoNotifier, DeviceInfoModel>(
  DeviceInfoNotifier.new,
);

class DeviceInfoNotifier extends AsyncNotifier<DeviceInfoModel> {
  @override
  Future<DeviceInfoModel> build() async {
    return ref.read(deviceRepositoryProvider).getDeviceInfo();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(deviceRepositoryProvider).getDeviceInfo(),
    );
  }
}
