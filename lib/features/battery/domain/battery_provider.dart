import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/battery_repository.dart';
import 'battery_info.dart';

final batteryRepositoryProvider = Provider<BatteryRepository>((ref) {
  final repo = BatteryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final batteryInfoProvider =
    AsyncNotifierProvider<BatteryInfoNotifier, BatteryInfo>(
  BatteryInfoNotifier.new,
);

class BatteryInfoNotifier extends AsyncNotifier<BatteryInfo> {
  StreamSubscription<BatteryState>? _subscription;

  @override
  Future<BatteryInfo> build() async {
    final repo = ref.read(batteryRepositoryProvider);

    _subscription?.cancel();
    _subscription = repo.onBatteryStateChanged.listen((_) {
      _refresh();
    });

    ref.onDispose(() => _subscription?.cancel());

    return repo.getBatteryInfo();
  }

  Future<void> _refresh() async {
    final repo = ref.read(batteryRepositoryProvider);
    state = AsyncValue.data(await repo.getBatteryInfo());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(batteryRepositoryProvider).getBatteryInfo(),
    );
  }
}

// Charge alarm settings
final chargeAlarmEnabledProvider =
    NotifierProvider<ChargeAlarmEnabledNotifier, bool>(
  ChargeAlarmEnabledNotifier.new,
);

class ChargeAlarmEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool value) => state = value;
}

final chargeAlarmPercentProvider =
    NotifierProvider<ChargeAlarmPercentNotifier, int>(
  ChargeAlarmPercentNotifier.new,
);

class ChargeAlarmPercentNotifier extends Notifier<int> {
  @override
  int build() => 80;

  void set(int value) => state = value;
}
