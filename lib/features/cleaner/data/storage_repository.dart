import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../platform/native_platform_channel.dart';
import '../domain/storage_info.dart';

class StorageRepository {
  Future<StorageInfo> getStorageInfo() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return _getPlatformStorageInfo();
      }
      return StorageInfo.empty();
    } catch (e) {
      debugPrint('StorageRepository error: $e');
      return StorageInfo.empty();
    }
  }

  Future<StorageInfo> _getPlatformStorageInfo() async {
    final data = await NativePlatformChannel.getStorageInfo();
    final tempDir = await getTemporaryDirectory();
    final cacheSize = await _dirSize(tempDir);

    final totalBytes = (data['totalBytes'] as num?)?.toInt() ?? 0;
    final freeBytes = (data['freeBytes'] as num?)?.toInt() ?? 0;
    final usedBytes =
        (data['usedBytes'] as num?)?.toInt() ?? (totalBytes - freeBytes);

    if (totalBytes == 0) {
      return StorageInfo(
        totalBytes: 128 * 1024 * 1024 * 1024,
        freeBytes: 40 * 1024 * 1024 * 1024,
        usedBytes: 88 * 1024 * 1024 * 1024,
        photosBytes: 0,
        videosBytes: 0,
        cacheBytes: cacheSize,
        otherBytes: 0,
      );
    }

    return StorageInfo(
      totalBytes: totalBytes,
      freeBytes: freeBytes,
      usedBytes: usedBytes,
      photosBytes: 0,
      videosBytes: 0,
      cacheBytes: cacheSize,
      otherBytes: 0,
    );
  }

  Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      return _dirSize(tempDir);
    } catch (e) {
      return 0;
    }
  }

  Future<int> _dirSize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (_) {}
    return size;
  }

  Future<int> clearAppCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sizeBefore = await _dirSize(tempDir);
      
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
      
      return sizeBefore;
    } catch (e) {
      debugPrint('Clear cache error: $e');
      return 0;
    }
  }
}
