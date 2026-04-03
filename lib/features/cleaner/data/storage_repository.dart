import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
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
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
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

  // --- Media scanning ---

  Future<List<CleanableItem>> findScreenshots() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return [];

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );

      AssetPathEntity? screenshotAlbum;
      for (final album in albums) {
        final name = album.name.toLowerCase();
        if (name == 'screenshots' || name == 'ekran görüntüleri') {
          screenshotAlbum = album;
          break;
        }
      }

      if (screenshotAlbum == null) {
        return _findScreenshotsByName(albums);
      }

      final count = await screenshotAlbum.assetCountAsync;
      if (count == 0) return [];

      final assets = await screenshotAlbum.getAssetListRange(
        start: 0,
        end: count.clamp(0, 500),
      );

      return _assetsToCleanableItems(assets, CleanableType.screenshot);
    } catch (e) {
      debugPrint('findScreenshots error: $e');
      return [];
    }
  }

  Future<List<CleanableItem>> _findScreenshotsByName(
      List<AssetPathEntity> albums) async {
    final items = <CleanableItem>[];

    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count == 0) continue;

      final assets = await album.getAssetListRange(
        start: 0,
        end: count.clamp(0, 1000),
      );

      for (final asset in assets) {
        final title = (asset.title ?? '').toLowerCase();
        if (title.contains('screenshot') ||
            title.contains('ekran') ||
            title.startsWith('img_') && asset.width == asset.height) {
          final file = await asset.file;
          if (file != null) {
            final size = await file.length();
            items.add(CleanableItem(
              id: asset.id,
              name: asset.title ?? 'screenshot',
              path: file.path,
              sizeBytes: size,
              type: CleanableType.screenshot,
              createdAt: asset.createDateTime,
            ));
          }
        }
        if (items.length >= 200) break;
      }
      if (items.length >= 200) break;
    }

    return items;
  }

  Future<List<CleanableItem>> findLargeFiles({int minBytes = 20 * 1024 * 1024}) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return [];

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );

      if (albums.isEmpty) return [];

      final allAlbum = albums.first;
      final count = await allAlbum.assetCountAsync;
      if (count == 0) return [];

      final items = <CleanableItem>[];
      const batchSize = 100;

      for (int start = 0; start < count && items.length < 100; start += batchSize) {
        final end = (start + batchSize).clamp(0, count);
        final assets = await allAlbum.getAssetListRange(start: start, end: end);

        for (final asset in assets) {
          final file = await asset.file;
          if (file == null) continue;

          final size = await file.length();
          if (size >= minBytes) {
            items.add(CleanableItem(
              id: asset.id,
              name: asset.title ?? 'file',
              path: file.path,
              sizeBytes: size,
              type: CleanableType.largeFile,
              createdAt: asset.createDateTime,
            ));
          }
        }
      }

      items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      return items;
    } catch (e) {
      debugPrint('findLargeFiles error: $e');
      return [];
    }
  }

  Future<List<List<CleanableItem>>> findSimilarPhotos() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return [];

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      if (albums.isEmpty) return [];

      final allAlbum = albums.first;
      final count = await allAlbum.assetCountAsync;
      if (count == 0) return [];

      final limit = count.clamp(0, 500);
      final assets = await allAlbum.getAssetListRange(start: 0, end: limit);

      // Group by creation time proximity (within 3 seconds) and similar dimensions
      final groups = <List<AssetEntity>>[];
      final used = <int>{};

      for (int i = 0; i < assets.length; i++) {
        if (used.contains(i)) continue;

        final group = [assets[i]];
        final baseTime = assets[i].createDateTime;
        final baseWidth = assets[i].width;
        final baseHeight = assets[i].height;

        for (int j = i + 1; j < assets.length; j++) {
          if (used.contains(j)) continue;

          final dt = assets[j].createDateTime.difference(baseTime).abs();
          final sameSize = assets[j].width == baseWidth &&
              assets[j].height == baseHeight;

          if (dt.inSeconds <= 3 && sameSize) {
            group.add(assets[j]);
            used.add(j);
          }
        }

        if (group.length >= 2) {
          used.add(i);
          groups.add(group);
        }
      }

      final result = <List<CleanableItem>>[];
      for (final group in groups) {
        final items = <CleanableItem>[];
        for (final asset in group) {
          final file = await asset.file;
          if (file != null) {
            final size = await file.length();
            items.add(CleanableItem(
              id: asset.id,
              name: asset.title ?? 'photo',
              path: file.path,
              sizeBytes: size,
              type: CleanableType.duplicatePhoto,
              createdAt: asset.createDateTime,
            ));
          }
        }
        if (items.length >= 2) {
          result.add(items);
        }
        if (result.length >= 50) break;
      }

      return result;
    } catch (e) {
      debugPrint('findSimilarPhotos error: $e');
      return [];
    }
  }

  Future<bool> deleteMediaItems(List<CleanableItem> items) async {
    try {
      final ids = items.map((e) => e.id).toList();
      final result = await PhotoManager.editor.deleteWithIds(ids);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('deleteMediaItems error: $e');
      return false;
    }
  }

  Future<Uint8List?> getThumbnail(String assetId) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) return null;
      return asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    } catch (_) {
      return null;
    }
  }

  Future<List<CleanableItem>> _assetsToCleanableItems(
    List<AssetEntity> assets,
    CleanableType type,
  ) async {
    final items = <CleanableItem>[];
    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) {
        final size = await file.length();
        items.add(CleanableItem(
          id: asset.id,
          name: asset.title ?? 'file',
          path: file.path,
          sizeBytes: size,
          type: type,
          createdAt: asset.createDateTime,
        ));
      }
    }
    return items;
  }
}
