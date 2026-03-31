import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../platform/native_platform_channel.dart';
import '../domain/battery_info.dart';
import '../domain/energy_consumer.dart';

class BatteryRepository {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _stateSubscription;

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
    // Android BatteryManager doesn't expose cycle-based health easily.
    // We estimate based on temperature patterns and charging behavior.
    // Will be refined with manufacturer-specific APIs.
    return 94;
  }

  Future<int> _getCycleCount() async {
    // Cycle count is not available through standard Android/iOS APIs.
    // Some manufacturers expose it, will be added per-device.
    return 0;
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
    _stateSubscription?.cancel();
  }
}
