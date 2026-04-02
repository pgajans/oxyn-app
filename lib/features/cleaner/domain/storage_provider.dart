import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_repository.dart';
import 'storage_info.dart';

const _freeCleanUsedKey = 'free_clean_used';

final freeCleanAvailableProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_freeCleanUsedKey) ?? false);
});

Future<void> markFreeCleanUsed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_freeCleanUsedKey, true);
}

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

    try {
      final results = await Future.wait([
        repo.getCacheSize(),
        repo.findScreenshots(),
        repo.findLargeFiles(),
        repo.findSimilarPhotos(),
      ]);

      final cacheSize = results[0] as int;
      final screenshots = results[1] as List<CleanableItem>;
      final largeFiles = results[2] as List<CleanableItem>;
      final similarGroups = results[3] as List<List<CleanableItem>>;

      final duplicateBytes =
          similarGroups.expand((g) => g.skip(1)).fold(0, (sum, item) => sum + item.sizeBytes);
      final screenshotBytes =
          screenshots.fold(0, (sum, item) => sum + item.sizeBytes);
      final largeFileBytes =
          largeFiles.fold(0, (sum, item) => sum + item.sizeBytes);

      state = AsyncValue.data(ScanResult(
        similarPhotoGroups: similarGroups,
        largeFiles: largeFiles,
        screenshots: screenshots,
        totalCleanableBytes:
            cacheSize + duplicateBytes + screenshotBytes + largeFileBytes,
        cacheBytes: cacheSize,
        hasScanned: true,
      ));
    } catch (e) {
      final cacheSize = await repo.getCacheSize();
      state = AsyncValue.data(ScanResult(
        similarPhotoGroups: [],
        largeFiles: [],
        screenshots: [],
        totalCleanableBytes: cacheSize,
        cacheBytes: cacheSize,
        hasScanned: true,
      ));
    }
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
