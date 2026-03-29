import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../domain/device_info_model.dart';

class DeviceRepository {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<DeviceInfoModel> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return _getAndroidInfo();
      } else if (Platform.isIOS) {
        return _getIOSInfo();
      }
      return DeviceInfoModel.empty();
    } catch (e) {
      debugPrint('DeviceRepository error: $e');
      return DeviceInfoModel.empty();
    }
  }

  Future<DeviceInfoModel> _getAndroidInfo() async {
    final info = await _deviceInfo.androidInfo;
    return DeviceInfoModel(
      model: '${info.brand} ${info.model}',
      osVersion: 'Android ${info.version.release}',
      totalStorage: '—',
      usedStorage: '—',
      freeStorage: '—',
      cpuTemperature: 0, // will use platform channel for thermal API
      ramUsage: '—',
      totalRam: '—',
    );
  }

  Future<DeviceInfoModel> _getIOSInfo() async {
    final info = await _deviceInfo.iosInfo;
    return DeviceInfoModel(
      model: info.utsname.machine,
      osVersion: '${info.systemName} ${info.systemVersion}',
      totalStorage: '—',
      usedStorage: '—',
      freeStorage: '—',
      cpuTemperature: 0, // iOS doesn't expose CPU temp directly
      ramUsage: '—',
      totalRam: '—',
    );
  }
}
