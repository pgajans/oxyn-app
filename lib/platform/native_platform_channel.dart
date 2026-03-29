import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativePlatformChannel {
  static const _channel = MethodChannel('com.oxynapp.oxyn/platform');

  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getStorageInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Platform channel getStorageInfo error: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getBatteryDetails() async {
    try {
      final result = await _channel.invokeMethod<Map>('getBatteryDetails');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Platform channel getBatteryDetails error: $e');
      return {};
    }
  }

  static Future<double> getCpuTemperature() async {
    try {
      final result = await _channel.invokeMethod<double>('getCpuTemperature');
      return result ?? 0.0;
    } catch (e) {
      debugPrint('Platform channel getCpuTemperature error: $e');
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
