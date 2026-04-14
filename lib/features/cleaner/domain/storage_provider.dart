import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_repository.dart';
import 'storage_info.dart';

const _freeCleanUsedKey = 'free_clean_used';
const _lastFreeCleanKey = 'last_free_clean_time';
const _freeCleanCooldownDays = 7;

final freeCleanAvailableProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastCleanTime = prefs.getInt(_lastFreeCleanKey);
  if (lastCleanTime == null) return true;

  final lastClean = DateTime.fromMillisecondsSinceEpoch(lastCleanTime);
  final elapsed = DateTime.now().difference(lastClean);
  return elapsed.inDays >= _freeCleanCooldownDays;
});

final freeCleanRemainingProvider = FutureProvider<Duration>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastCleanTime = prefs.getInt(_lastFreeCleanKey);
  if (lastCleanTime == null) return Duration.zero;

  final lastClean = DateTime.fromMillisecondsSinceEpoch(lastCleanTime);
  final cooldownEnd =
      lastClean.add(const Duration(days: _freeCleanCooldownDays));
  final remaining = cooldownEnd.difference(DateTime.now());
  return remaining.isNegative ? Duration.zero : remaining;
});

Future<void> markFreeCleanUsed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_freeCleanUsedKey, true);
  await prefs.setInt(_lastFreeCleanKey, DateTime.now().millisecondsSinceEpoch);
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

final scanProgressProvider =
    NotifierProvider<ScanProgressNotifier, ScanProgress>(
  ScanProgressNotifier.new,
);

class ScanProgress {
  final String currentStep;
  final int stepIndex;
  final int totalSteps;
  final bool isScanning;
  final bool timedOut;

  const ScanProgress({
    this.currentStep = '',
    this.stepIndex = 0,
    this.totalSteps = 4,
    this.isScanning = false,
    this.timedOut = false,
  });

  double get progress =>
      totalSteps > 0 ? stepIndex / totalSteps : 0;
}

class ScanProgressNotifier extends Notifier<ScanProgress> {
  @override
  ScanProgress build() => const ScanProgress();

  void start() =>
      state = const ScanProgress(isScanning: true, currentStep: 'Hazırlanıyor...');

  void update(String step, int index) =>
      state = ScanProgress(
        currentStep: step,
        stepIndex: index,
        isScanning: true,
      );

  void complete() =>
      state = const ScanProgress(isScanning: false, stepIndex: 4);

  void timeout() =>
      state = const ScanProgress(isScanning: false, timedOut: true);
}

class ScanResultNotifier extends AsyncNotifier<ScanResult> {
  @override
  Future<ScanResult> build() async {
    return ScanResult.empty();
  }

  Future<void> startScan() async {
    state = const AsyncValue.loading();
    final progress = ref.read(scanProgressProvider.notifier);
    progress.start();

    final repo = ref.read(storageRepositoryProvider);

    try {
      await _runScanWithTimeout(repo, progress);
    } catch (e) {
      if (e is TimeoutException) {
        progress.timeout();
      } else {
        progress.complete();
      }
      final cacheSize =
          await repo.getCacheSize().timeout(
                const Duration(seconds: 5),
                onTimeout: () => 0,
              );
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

  Future<void> _runScanWithTimeout(
    StorageRepository repo,
    ScanProgressNotifier progress,
  ) async {
    await _performScan(repo, progress).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('Scan timed out'),
    );
  }

  Future<void> _performScan(
    StorageRepository repo,
    ScanProgressNotifier progress,
  ) async {
    progress.update('Cache kontrol ediliyor...', 1);
    final cacheSize = await repo.getCacheSize()
        .timeout(const Duration(seconds: 10), onTimeout: () => 0);

    progress.update('Ekran görüntüleri taranıyor...', 2);
    final screenshots = await repo.findScreenshots()
        .timeout(const Duration(seconds: 15), onTimeout: () => <CleanableItem>[]);

    progress.update('Büyük dosyalar aranıyor...', 3);
    final largeFiles = await repo.findLargeFiles()
        .timeout(const Duration(seconds: 15), onTimeout: () => <CleanableItem>[]);

    progress.update('Fotoğraflar karşılaştırılıyor...', 4);
    final similarGroups = await repo.findSimilarPhotos()
        .timeout(const Duration(seconds: 20), onTimeout: () => <List<CleanableItem>>[]);

    final duplicateBytes = similarGroups
        .expand((g) => g.skip(1))
        .fold(0, (sum, item) => sum + item.sizeBytes);
    final screenshotBytes =
        screenshots.fold(0, (sum, item) => sum + item.sizeBytes);
    final largeFileBytes =
        largeFiles.fold(0, (sum, item) => sum + item.sizeBytes);

    progress.complete();

    state = AsyncValue.data(ScanResult(
      similarPhotoGroups: similarGroups,
      largeFiles: largeFiles,
      screenshots: screenshots,
      totalCleanableBytes:
          cacheSize + duplicateBytes + screenshotBytes + largeFileBytes,
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
