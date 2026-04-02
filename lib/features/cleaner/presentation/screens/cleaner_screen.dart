import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../data/storage_repository.dart';
import '../../domain/storage_info.dart';
import '../../domain/storage_provider.dart';
import '../../../subscription/domain/subscription_provider.dart';

class CleanerScreen extends ConsumerWidget {
  const CleanerScreen({super.key});

  Future<bool> _canClean(BuildContext context, WidgetRef ref) async {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return true;

    final freeAvailable = await ref.read(freeCleanAvailableProvider.future);
    if (freeAvailable) return true;

    if (context.mounted) {
      context.push('/paywall');
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageInfoProvider);
    final scanAsync = ref.watch(scanResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Temizlik')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            storageAsync.when(
              loading: () => const OxynCard(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => OxynCard(
                child: Text('Depolama bilgisi alınamadı: $e'),
              ),
              data: (storage) => _StorageOverview(
                total: storage.totalFormatted,
                used: storage.usedFormatted,
                free: storage.freeFormatted,
                usedPercent: storage.usedPercent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            scanAsync.when(
              loading: () => Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Taranıyor...',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              error: (e, s) => const SizedBox.shrink(),
              data: (scan) {
                if (!scan.hasScanned) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(scanResultProvider.notifier).startScan(),
                      icon: const Icon(Icons.search),
                      label: const Text('Taramayı Başlat'),
                    ),
                  );
                }
                return _ScanResultCard(scan: scan, ref: ref);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            scanAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (scan) => Column(
                children: [
                  _CleaningCategory(
                    icon: Icons.photo_library,
                    title: 'Benzer Fotoğraflar',
                    subtitle: scan.hasScanned
                        ? '${scan.similarPhotoGroups.length} grup bulundu'
                        : 'Galeriyi tarayarak benzer fotoğrafları bul',
                    size: scan.hasScanned && scan.similarPhotosBytes > 0
                        ? StorageInfo.formatBytes(scan.similarPhotosBytes)
                        : '—',
                    color: AppColors.secondary,
                    onTap: () async {
                      if (!scan.hasScanned || scan.similarPhotoGroups.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Önce taramayı başlatın'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (!await _canClean(context, ref)) return;
                      if (context.mounted) {
                        _showSimilarPhotos(context, ref, scan.similarPhotoGroups);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CleaningCategory(
                    icon: Icons.file_present,
                    title: 'Büyük Dosyalar',
                    subtitle: scan.hasScanned
                        ? '${scan.largeFiles.length} dosya (50MB+)'
                        : '50MB üzeri dosyalar',
                    size: scan.hasScanned && scan.largeFilesBytes > 0
                        ? StorageInfo.formatBytes(scan.largeFilesBytes)
                        : '—',
                    color: AppColors.danger,
                    onTap: () async {
                      if (!scan.hasScanned || scan.largeFiles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scan.hasScanned
                                ? '50MB üzeri dosya bulunamadı'
                                : 'Önce taramayı başlatın'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (!await _canClean(context, ref)) return;
                      if (context.mounted) {
                        _showLargeFiles(context, ref, scan.largeFiles);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CleaningCategory(
                    icon: Icons.screenshot,
                    title: 'Ekran Görüntüleri',
                    subtitle: scan.hasScanned
                        ? '${scan.screenshots.length} ekran görüntüsü'
                        : 'Eski ekran görüntülerini temizle',
                    size: scan.hasScanned && scan.screenshotsBytes > 0
                        ? StorageInfo.formatBytes(scan.screenshotsBytes)
                        : '—',
                    color: AppColors.primary,
                    onTap: () async {
                      if (!scan.hasScanned || scan.screenshots.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scan.hasScanned
                                ? 'Ekran görüntüsü bulunamadı'
                                : 'Önce taramayı başlatın'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (!await _canClean(context, ref)) return;
                      if (context.mounted) {
                        _showScreenshots(context, ref, scan.screenshots);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CacheCategory(ref: ref),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showSimilarPhotos(
    BuildContext context,
    WidgetRef ref,
    List<List<CleanableItem>> groups,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SimilarPhotosPage(groups: groups, ref: ref),
      ),
    );
  }

  void _showLargeFiles(
    BuildContext context,
    WidgetRef ref,
    List<CleanableItem> files,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FileListPage(
          title: 'Büyük Dosyalar',
          items: files,
          ref: ref,
        ),
      ),
    );
  }

  void _showScreenshots(
    BuildContext context,
    WidgetRef ref,
    List<CleanableItem> screenshots,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FileListPage(
          title: 'Ekran Görüntüleri',
          items: screenshots,
          ref: ref,
        ),
      ),
    );
  }
}

// --- Detail Pages ---

class _SimilarPhotosPage extends StatefulWidget {
  final List<List<CleanableItem>> groups;
  final WidgetRef ref;

  const _SimilarPhotosPage({required this.groups, required this.ref});

  @override
  State<_SimilarPhotosPage> createState() => _SimilarPhotosPageState();
}

class _SimilarPhotosPageState extends State<_SimilarPhotosPage> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final totalSelected = _selected.length;
    final totalBytes = widget.groups
        .expand((g) => g)
        .where((item) => _selected.contains(item.id))
        .fold(0, (sum, item) => sum + item.sizeBytes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benzer Fotoğraflar'),
        actions: [
          if (totalSelected > 0)
            TextButton.icon(
              onPressed: () => _deleteSelected(),
              icon: const Icon(Icons.delete, color: AppColors.danger),
              label: Text(
                '$totalSelected sil (${StorageInfo.formatBytes(totalBytes)})',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: AppSpacing.screenPadding,
        itemCount: widget.groups.length,
        itemBuilder: (context, groupIndex) {
          final group = widget.groups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Grup ${groupIndex + 1} (${group.length} fotoğraf)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: group.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, itemIndex) {
                    final item = group[itemIndex];
                    final isSelected = _selected.contains(item.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(item.id);
                          } else {
                            _selected.add(item.id);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.danger, width: 3)
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _ThumbnailWidget(assetId: item.id),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.sizeFormatted,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 24, color: AppColors.textTertiary.withValues(alpha: 0.3)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Fotoğrafları Sil'),
        content: Text('${_selected.length} fotoğraf silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final items = widget.groups
        .expand((g) => g)
        .where((item) => _selected.contains(item.id))
        .toList();

    final repo = widget.ref.read(storageRepositoryProvider);
    final success = await repo.deleteMediaItems(items);

    if (!mounted) return;
    if (success) {
      await markFreeCleanUsed();
      widget.ref.invalidate(freeCleanAvailableProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${items.length} fotoğraf silindi'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.ref.read(scanResultProvider.notifier).startScan();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silme işlemi başarısız oldu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _FileListPage extends StatefulWidget {
  final String title;
  final List<CleanableItem> items;
  final WidgetRef ref;

  const _FileListPage({
    required this.title,
    required this.items,
    required this.ref,
  });

  @override
  State<_FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<_FileListPage> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final totalBytes = widget.items
        .where((item) => _selected.contains(item.id))
        .fold(0, (sum, item) => sum + item.sizeBytes);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: () => _deleteSelected(),
              icon: const Icon(Icons.delete, color: AppColors.danger),
              label: Text(
                '${_selected.length} sil (${StorageInfo.formatBytes(totalBytes)})',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
      body: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: widget.items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = _selected.contains(item.id);

          return OxynCard(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(item.id);
                } else {
                  _selected.add(item.id);
                }
              });
            },
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ThumbnailWidget(assetId: item.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.sizeFormatted,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(item.id);
                      } else {
                        _selected.remove(item.id);
                      }
                    });
                  },
                  activeColor: AppColors.danger,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _selected.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(
                    '${_selected.length} Dosya Sil (${StorageInfo.formatBytes(totalBytes)})',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Dosyaları Sil'),
        content: Text(
            '${_selected.length} dosya silinecek. Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final items = widget.items
        .where((item) => _selected.contains(item.id))
        .toList();

    final repo = widget.ref.read(storageRepositoryProvider);
    final success = await repo.deleteMediaItems(items);

    if (!mounted) return;
    if (success) {
      await markFreeCleanUsed();
      widget.ref.invalidate(freeCleanAvailableProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${items.length} dosya silindi'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.ref.read(scanResultProvider.notifier).startScan();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silme işlemi başarısız oldu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// --- Thumbnail Widget ---

class _ThumbnailWidget extends StatefulWidget {
  final String assetId;

  const _ThumbnailWidget({required this.assetId});

  @override
  State<_ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<_ThumbnailWidget> {
  Uint8List? _data;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final repo = StorageRepository();
    final data = await repo.getThumbnail(widget.assetId);
    if (mounted) {
      setState(() => _data = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return Container(
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.image, color: AppColors.textTertiary, size: 24),
        ),
      );
    }
    return Image.memory(_data!, fit: BoxFit.cover);
  }
}

// --- Existing widgets ---

class _ScanResultCard extends StatelessWidget {
  final ScanResult scan;
  final WidgetRef ref;

  const _ScanResultCard({required this.scan, required this.ref});

  @override
  Widget build(BuildContext context) {
    final totalCleanable = scan.totalCleanableBytes;
    final hasItems = totalCleanable > 0;
    final isPremium = ref.watch(isPremiumProvider);
    final freeCleanAsync = ref.watch(freeCleanAvailableProvider);
    final hasFreeClean = freeCleanAsync.value ?? false;

    return OxynCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            hasItems ? Icons.cleaning_services : Icons.check_circle,
            color: hasItems ? AppColors.secondary : AppColors.success,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            hasItems
                ? 'Temizlenebilir: ${scan.totalCleanableFormatted}'
                : 'Cihazın temiz!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasItems) ...[
            const SizedBox(height: 4),
            Text(
              '${scan.totalItemCount} öğe bulundu',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (!isPremium && hasFreeClean)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'İlk temizlik ücretsiz!',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!isPremium && hasFreeClean)
              const SizedBox(height: 8),
          ],
          if (!hasItems) ...[
            const SizedBox(height: 8),
            const Text(
              'Temizlenecek bir şey bulunamadı',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                ref.read(scanResultProvider.notifier).startScan(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tekrar Tara'),
          ),
        ],
      ),
    );
  }
}

class _StorageOverview extends StatelessWidget {
  final String total;
  final String used;
  final String free;
  final double usedPercent;

  const _StorageOverview({
    required this.total,
    required this.used,
    required this.free,
    required this.usedPercent,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Depolama',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                used,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' / $total',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usedPercent / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                usedPercent > 90 ? AppColors.danger : AppColors.primary,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kullanılan: $used',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Boş: $free',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CleaningCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String size;
  final Color color;
  final VoidCallback onTap;

  const _CleaningCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (size != '—')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                size,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _CacheCategory extends StatelessWidget {
  final WidgetRef ref;

  const _CacheCategory({required this.ref});

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Önbellek Temizle'),
            content: const Text(
                'Uygulama önbelleğini temizlemek istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Temizle'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final repo = ref.read(storageRepositoryProvider);
          final cleaned = await repo.clearAppCache();
          ref.invalidate(storageInfoProvider);

          if (context.mounted) {
            final mb = (cleaned / (1024 * 1024)).toStringAsFixed(1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$mb MB önbellek temizlendi!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.cached, color: AppColors.tertiary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Önbellek',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Uygulama önbelleğini temizle',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
