class StorageInfo {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;
  final int photosBytes;
  final int videosBytes;
  final int cacheBytes;
  final int otherBytes;

  const StorageInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
    required this.photosBytes,
    required this.videosBytes,
    required this.cacheBytes,
    required this.otherBytes,
  });

  factory StorageInfo.empty() => const StorageInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        photosBytes: 0,
        videosBytes: 0,
        cacheBytes: 0,
        otherBytes: 0,
      );

  double get usedPercent =>
      totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;

  double get freePercent =>
      totalBytes > 0 ? (freeBytes / totalBytes) * 100 : 0;

  String get totalFormatted => formatBytes(totalBytes);
  String get freeFormatted => formatBytes(freeBytes);
  String get usedFormatted => formatBytes(usedBytes);
  String get photosFormatted => formatBytes(photosBytes);
  String get videosFormatted => formatBytes(videosBytes);
  String get cacheFormatted => formatBytes(cacheBytes);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${suffixes[i]}';
  }
}

class CleanableItem {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final CleanableType type;
  final String? thumbnailPath;
  final DateTime? createdAt;

  const CleanableItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.type,
    this.thumbnailPath,
    this.createdAt,
  });

  String get sizeFormatted => StorageInfo.formatBytes(sizeBytes);
}

enum CleanableType {
  duplicatePhoto,
  screenshot,
  largeFile,
  cache,
  video,
}

class ScanResult {
  final List<CleanableItem> duplicatePhotos;
  final List<CleanableItem> largeFiles;
  final List<CleanableItem> screenshots;
  final int totalCleanableBytes;
  final int cacheBytes;
  final bool hasScanned;

  const ScanResult({
    required this.duplicatePhotos,
    required this.largeFiles,
    required this.screenshots,
    required this.totalCleanableBytes,
    this.cacheBytes = 0,
    this.hasScanned = false,
  });

  factory ScanResult.empty() => const ScanResult(
        duplicatePhotos: [],
        largeFiles: [],
        screenshots: [],
        totalCleanableBytes: 0,
        cacheBytes: 0,
        hasScanned: false,
      );

  String get totalCleanableFormatted =>
      StorageInfo.formatBytes(totalCleanableBytes);

  int get totalItemCount =>
      duplicatePhotos.length + largeFiles.length + screenshots.length;
}
