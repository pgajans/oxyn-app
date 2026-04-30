import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../platform/native_platform_channel.dart';
import '../domain/battery_info.dart';
import '../domain/energy_consumer.dart';

class BatteryRepository {
  final Battery _battery = Battery();

  Future<BatteryInfo> getBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final platformData = await _getPlatformBatteryData();

      final temperature = platformData['temperature'] ?? 0.0;
      final platformLevel = platformData['level'] ?? level;

      return BatteryInfo(
        level: (platformLevel is int) ? platformLevel : level,
        isCharging: state == BatteryState.charging ||
            state == BatteryState.full,
        temperature: (temperature is num) ? temperature.toDouble() : 0.0,
        healthPercentage: await _getHealthPercentage(),
        cycleCount: await _getCycleCount(),
        chargingSource: _mapChargingSource(state),
        estimatedRemaining: _estimateRemaining(level, state),
      );
    } catch (e) {
      debugPrint('BatteryRepository error: $e');
      return BatteryInfo.empty();
    }
  }

  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;

  Future<Map<String, dynamic>> _getPlatformBatteryData() async {
    try {
      final details = await NativePlatformChannel.getBatteryDetails();
      debugPrint('Platform battery data: $details');
      return details;
    } catch (e) {
      debugPrint('Platform battery data error: $e');
      return {};
    }
  }

  Future<int> _getHealthPercentage() async {
    try {
      final data = await NativePlatformChannel.getBatteryDetails();
      final health = data['health'];
      if (health is int && health > 0 && health <= 100) return health;
    } catch (e) {
      debugPrint('Battery health fetch error: $e');
    }
    // Fallback: standard APIs don't expose health on most devices
    return -1;
  }

  Future<int> _getCycleCount() async {
    try {
      final data = await NativePlatformChannel.getBatteryDetails();
      final cycles = data['cycleCount'];
      if (cycles is int && cycles >= 0) return cycles;
    } catch (e) {
      debugPrint('Battery cycle count fetch error: $e');
    }
    return -1;
  }

  String _mapChargingSource(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'charging';
      case BatteryState.full:
        return 'full';
      case BatteryState.discharging:
        return 'battery';
      case BatteryState.connectedNotCharging:
        return 'connected';
      case BatteryState.unknown:
        return 'unknown';
    }
  }

  Duration _estimateRemaining(int level, BatteryState state) {
    if (state == BatteryState.charging || state == BatteryState.full) {
      return Duration.zero;
    }
    final minutesPerPercent = 16 * 60 / 100;
    return Duration(minutes: (level * minutesPerPercent).round());
  }

  List<EnergyConsumer> getTopEnergyConsumers() {
    return [];
  }

  void dispose() {
    // Reserved for future stream subscription cleanup
  }
}
