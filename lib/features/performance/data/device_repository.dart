import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../platform/native_platform_channel.dart';
import '../../cleaner/domain/storage_info.dart';
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
    final storageData = await NativePlatformChannel.getStorageInfo();
    final cpuTemp = await NativePlatformChannel.getCpuTemperature();

    final totalBytes = (storageData['totalBytes'] as num?)?.toInt() ?? 0;
    final freeBytes = (storageData['freeBytes'] as num?)?.toInt() ?? 0;
    final usedBytes = (storageData['usedBytes'] as num?)?.toInt() ?? 0;

    return DeviceInfoModel(
      model: '${info.brand} ${info.model}',
      osVersion: 'Android ${info.version.release}',
      totalStorage: totalBytes > 0 ? StorageInfo.formatBytes(totalBytes) : '—',
      usedStorage: usedBytes > 0 ? StorageInfo.formatBytes(usedBytes) : '—',
      freeStorage: freeBytes > 0 ? StorageInfo.formatBytes(freeBytes) : '—',
      cpuTemperature: cpuTemp,
      ramUsage: '—',
      totalRam: '—',
    );
  }

  Future<DeviceInfoModel> _getIOSInfo() async {
    final info = await _deviceInfo.iosInfo;
    final storageData = await NativePlatformChannel.getStorageInfo();

    final totalBytes = (storageData['totalBytes'] as num?)?.toInt() ?? 0;
    final freeBytes = (storageData['freeBytes'] as num?)?.toInt() ?? 0;
    final usedBytes = (storageData['usedBytes'] as num?)?.toInt() ?? 0;

    return DeviceInfoModel(
      model: info.utsname.machine,
      osVersion: '${info.systemName} ${info.systemVersion}',
      totalStorage: totalBytes > 0 ? StorageInfo.formatBytes(totalBytes) : '—',
      usedStorage: usedBytes > 0 ? StorageInfo.formatBytes(usedBytes) : '—',
      freeStorage: freeBytes > 0 ? StorageInfo.formatBytes(freeBytes) : '—',
      cpuTemperature: 0,
      ramUsage: '—',
      totalRam: '—',
    );
  }
}
