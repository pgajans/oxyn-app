import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/storage_info.dart';

class StorageRepository {
  Future<StorageInfo> getStorageInfo() async {
    try {
      if (Platform.isAndroid) {
        return _getAndroidStorageInfo();
      } else if (Platform.isIOS) {
        return _getIOSStorageInfo();
      }
      return StorageInfo.empty();
    } catch (e) {
      debugPrint('StorageRepository error: $e');
      return StorageInfo.empty();
    }
  }

  Future<StorageInfo> _getAndroidStorageInfo() async {
    final tempDir = await getTemporaryDirectory();
    final cacheSize = await _dirSize(tempDir);

    return StorageInfo(
      totalBytes: 256 * 1024 * 1024 * 1024, // placeholder until platform channel
      freeBytes: 69 * 1024 * 1024 * 1024,
      usedBytes: 187 * 1024 * 1024 * 1024,
      photosBytes: 0,
      videosBytes: 0,
      cacheBytes: cacheSize,
      otherBytes: 0,
    );
  }

  Future<StorageInfo> _getIOSStorageInfo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheSize = await _dirSize(tempDir);

      // iOS provides storage info through FileManager
      // Real implementation via platform channel
      return StorageInfo(
        totalBytes: 256 * 1024 * 1024 * 1024,
        freeBytes: 69 * 1024 * 1024 * 1024,
        usedBytes: 187 * 1024 * 1024 * 1024,
        photosBytes: 0,
        videosBytes: 0,
        cacheBytes: cacheSize,
        otherBytes: 0,
      );
    } catch (e) {
      return StorageInfo.empty();
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
