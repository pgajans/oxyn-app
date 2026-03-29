import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import '../domain/battery_info.dart';
import '../domain/energy_consumer.dart';

class BatteryRepository {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _stateSubscription;

  Future<BatteryInfo> getBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      return BatteryInfo(
        level: level,
        isCharging: state == BatteryState.charging ||
            state == BatteryState.full,
        temperature: await _getTemperature(),
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

  Future<double> _getTemperature() async {
    // battery_plus doesn't provide temperature directly
    // On Android, we'll use platform channel; on iOS, limited access
    // For now, return a reasonable default; will be replaced with platform channel
    return 31.0;
  }

  Future<int> _getHealthPercentage() async {
    // iOS provides battery health via private API (limited)
    // Android provides via BatteryManager
    // Will be implemented via platform channel
    return 94;
  }

  Future<int> _getCycleCount() async {
    // iOS: Available via IOKit (limited access)
    // Android: Available via BatteryManager on some devices
    // Will be implemented via platform channel
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
    // Rough estimation: average phone lasts ~16h on full charge
    final minutesPerPercent = 16 * 60 / 100;
    return Duration(minutes: (level * minutesPerPercent).round());
  }

  List<EnergyConsumer> getTopEnergyConsumers() {
    // On Android: UsageStatsManager provides real data
    // On iOS: Limited to Settings > Battery redirect
    // For MVP, we'll show guidance to check battery settings
    // Real data will come from platform channel on Android
    return [];
  }

  void dispose() {
    _stateSubscription?.cancel();
  }
}
