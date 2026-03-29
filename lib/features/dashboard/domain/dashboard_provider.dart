import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../battery/domain/battery_provider.dart';
import '../../cleaner/domain/storage_provider.dart';
import 'health_score.dart';

final healthScoreProvider = Provider<HealthScore>((ref) {
  final batteryAsync = ref.watch(batteryInfoProvider);
  final storageAsync = ref.watch(storageInfoProvider);

  return batteryAsync.when(
    loading: () => HealthScore.empty(),
    error: (e, s) => HealthScore.empty(),
    data: (battery) {
      final storageUsedPercent = storageAsync.when(
        loading: () => 50.0,
        error: (e, s) => 50.0,
        data: (storage) => storage.usedPercent,
      );

      return HealthScore.calculate(
        batteryLevel: battery.level,
        temperature: battery.temperature,
        storageUsedPercent: storageUsedPercent,
      );
    },
  );
});
