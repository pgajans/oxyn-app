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

    final repo = ref.read(storageRepositoryProvider);

    await Future.delayed(const Duration(milliseconds: 800));
    final cacheSize = await repo.getCacheSize();
    await Future.delayed(const Duration(milliseconds: 700));

    state = AsyncValue.data(ScanResult(
      duplicatePhotos: [],
      largeFiles: [],
      screenshots: [],
      totalCleanableBytes: cacheSize,
      cacheBytes: cacheSize,
      hasScanned: true,
    ));
  }

  Future<int> cleanCache() async {
    final repo = ref.read(storageRepositoryProvider);
    final cleaned = await repo.clearAppCache();
    await startScan();
    return cleaned;
  }
}

final cacheCleaningProvider = FutureProvider.autoDispose<int?>((ref) async {
  return null;
});
