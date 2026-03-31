import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativePlatformChannel {
  static const _channel = MethodChannel('com.oxynapp.oxyn/platform');

  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getStorageInfo');
      final data = Map<String, dynamic>.from(result ?? {});
      // #region agent log
      debugPrint('[DEBUG-53de45] NativePlatformChannel.getStorageInfo | result=$data');
      // #endregion
      return data;
    } catch (e) {
      // #region agent log
      debugPrint('[DEBUG-53de45] NativePlatformChannel.getStorageInfo | ERROR=$e');
      // #endregion
      return {};
    }
  }

  static Future<Map<String, dynamic>> getBatteryDetails() async {
    try {
      final result = await _channel.invokeMethod<Map>('getBatteryDetails');
      final data = Map<String, dynamic>.from(result ?? {});
      // #region agent log
      debugPrint('[DEBUG-53de45] NativePlatformChannel.getBatteryDetails | result=$data');
      // #endregion
      return data;
    } catch (e) {
      // #region agent log
      debugPrint('[DEBUG-53de45] NativePlatformChannel.getBatteryDetails | ERROR=$e');
      // #endregion
      return {};
    }
  }

  static Future<double> getCpuTemperature() async {
    try {
      final result = await _channel.invokeMethod<double>('getCpuTemperature');
      // #region agent log
      debugPrint('[DEBUG-53de45] NativePlatformChannel.getCpuTemperature | result=$result');
      // #endregion
      return result ?? 0.0;
    } catch (e) {
      // #region agent log
      debugPrint('[DEBUG-53de45] NativePlatformChannel.getCpuTemperature | ERROR=$e');
      // #endregion
      return 0.0;
    }
  }

  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('Platform channel openBatterySettings error: $e');
    }
  }
}
