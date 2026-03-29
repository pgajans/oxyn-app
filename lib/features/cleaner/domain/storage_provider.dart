import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/storage_repository.dart';
import 'storage_info.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

final storageInfoProvider =
    AsyncNotifierProvider<StorageInfoNotifier, StorageInfo>(
  StorageInfoNotifier.new,
);

class StorageInfoNotifier extends AsyncNotifier<StorageInfo> {
  @override
  Future<StorageInfo> build() async {
    return ref.read(storageRepositoryProvider).getStorageInfo();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(storageRepositoryProvider).getStorageInfo(),
    );
  }
}

final scanResultProvider =
    AsyncNotifierProvider<ScanResultNotifier, ScanResult>(
  ScanResultNotifier.new,
);

class ScanResultNotifier extends AsyncNotifier<ScanResult> {
  @override
  Future<ScanResult> build() async {
    return ScanResult.empty();
  }

  Future<void> startScan() async {
    state = const AsyncValue.loading();
    // Photo scanning will be implemented with photo_manager
    // For now, return empty result
    await Future.delayed(const Duration(seconds: 2));
    state = const AsyncValue.data(ScanResult(
      duplicatePhotos: [],
      largeFiles: [],
      screenshots: [],
      totalCleanableBytes: 0,
    ));
  }
}

final cacheCleaningProvider = FutureProvider.autoDispose<int?>((ref) async {
  return null;
});
