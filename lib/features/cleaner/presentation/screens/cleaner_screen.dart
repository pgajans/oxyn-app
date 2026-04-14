import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
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

    // Free clean used - show rewarded ad option
    if (context.mounted) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.play_circle_outline,
                  color: AppColors.secondary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Ücretsiz temizleme hakkınız doldu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reklam izleyerek temizleme yapabilir veya Premium\'a geçebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.cleaning_services, color: AppColors.background),
                  label: const Text('Temizle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                    context.push('/paywall');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.tertiary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Premium\'a Geç',
                    style: TextStyle(color: AppColors.tertiary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç', style: TextStyle(color: AppColors.textTertiary)),
              ),
            ],
          ),
        ),
      );
      return result == true;
    }
    return false;
  }

  Future<void> _requestPermissionAndScan(
      BuildContext context, WidgetRef ref) async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!context.mounted) return;

    if (ps.isAuth || ps == PermissionState.limited) {
      ref.read(scanResultProvider.notifier).startScan();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('İzin Gerekli'),
          content: const Text(
            'Fotoğraflarınızı taramak için galeri erişim izni gereklidir. '
            'Ayarlardan izin verebilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                PhotoManager.openSetting();
              },
              child: const Text('Ayarlara Git'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageInfoProvider);
    final scanAsync = ref.watch(scanResultProvider);
    final scanProgress = ref.watch(scanProgressProvider);

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
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
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
            if (scanProgress.isScanning)
              _ScanProgressCard(progress: scanProgress)
            else
              scanAsync.when(
                loading: () => const _ScanProgressCard(
                  progress: ScanProgress(
                    isScanning: true,
                    currentStep: 'Başlatılıyor...',
                  ),
                ),
                error: (e, s) => const SizedBox.shrink(),
                data: (scan) {
                  if (!scan.hasScanned) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _requestPermissionAndScan(context, ref),
                            icon: const Icon(Icons.search),
                            label: const Text('Taramayı Başlat'),
                          ),
                        ),
                      ],
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
                    title: 'Silmek İsteyebileceğiniz Fotoğraflar',
                    subtitle: scan.hasScanned
                        ? '${scan.similarPhotoGroups.length} grup bulundu'
                        : 'Galeriyi tarayarak benzer fotoğrafları bul',
                    size: scan.hasScanned && scan.similarPhotosBytes > 0
                        ? StorageInfo.formatBytes(scan.similarPhotosBytes)
                        : '—',
                    color: AppColors.secondary,
                    onTap: () async {
                      if (!scan.hasScanned ||
                          scan.similarPhotoGroups.isEmpty) {
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
                        _showSimilarPhotos(
                            context, ref, scan.similarPhotoGroups);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CleaningCategory(
                    icon: Icons.file_present,
                    title: 'Büyük Dosyalar',
                    subtitle: scan.hasScanned
                        ? '${scan.largeFiles.length} dosya (10MB+)'
                        : '10MB üzeri dosyalar',
                    size: scan.hasScanned && scan.largeFilesBytes > 0
                        ? StorageInfo.formatBytes(scan.largeFilesBytes)
                        : '—',
                    color: AppColors.danger,
                    onTap: () async {
                      if (!scan.hasScanned || scan.largeFiles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scan.hasScanned
                                ? '10MB üzeri dosya bulunamadı'
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

class _ScanProgressCard extends StatelessWidget {
  final ScanProgress progress;
  const _ScanProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (progress.timedOut) ...[
            const Icon(Icons.warning_amber,
                color: AppColors.warning, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Tarama tamamlanamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lütfen tekrar deneyin',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ] else ...[
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: progress.progress > 0 ? progress.progress : null,
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                progress.currentStep,
                key: ValueKey(progress.currentStep),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.stepIndex}/${progress.totalSteps}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.warning),
                  SizedBox(width: 6),
                  Text(
                    'Tarama bitene kadar ekranı kapatmayın',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanResultCard extends StatefulWidget {
  final ScanResult scan;
  final WidgetRef ref;
  const _ScanResultCard({required this.scan, required this.ref});

  @override
  State<_ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends State<_ScanResultCard>
    with TickerProviderStateMixin {
  late AnimationController _iconCtrl;
  late AnimationController _pulseCtrl;
  final List<_ScanStat> _visibleStats = [];
  bool _statsRevealed = false;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    if (widget.scan.hasScanned) {
      _iconCtrl.forward();
      _revealStats();
    }
  }

  Future<void> _revealStats() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final scan = widget.scan;
    final stats = <_ScanStat>[
      _ScanStat(Icons.photo_library, 'Fotoğraflar',
          '${scan.similarPhotoGroups.length} grup bulundu', AppColors.secondary),
      _ScanStat(Icons.file_present, 'Büyük Dosyalar',
          '${scan.largeFiles.length} dosya (10MB+)', AppColors.danger),
      _ScanStat(Icons.screenshot, 'Ekran Görüntüleri',
          '${scan.screenshots.length} adet', AppColors.primary),
      _ScanStat(Icons.cached, 'Önbellek',
          'Temizlenebilir alan mevcut', AppColors.warning),
    ];
    for (final stat in stats) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _visibleStats.add(stat));
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _statsRevealed = true);
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCleanable = widget.scan.totalCleanableBytes;
    final hasItems = totalCleanable > 0;
    final isPremium = widget.ref.watch(isPremiumProvider);
    final freeCleanAsync = widget.ref.watch(freeCleanAvailableProvider);
    final hasFreeClean = freeCleanAsync.value ?? false;
    final accentColor = hasItems ? AppColors.secondary : AppColors.success;

    return OxynCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _iconCtrl,
              curve: Curves.elasticOut,
            ),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final glow = hasItems ? 0.1 + _pulseCtrl.value * 0.15 : 0.15;
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: glow),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    hasItems ? Icons.manage_search_rounded : Icons.verified_rounded,
                    color: accentColor,
                    size: 32,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: CurvedAnimation(parent: _iconCtrl, curve: Curves.easeIn),
            child: Column(
              children: [
                Text(
                  hasItems ? 'Tarama Tamamlandı!' : 'Cihazın Temiz!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasItems
                      ? 'Temizlenebilir: ${widget.scan.totalCleanableFormatted}'
                      : 'Harika! Temizlenecek bir şey bulunamadı.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (hasItems) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.scan.totalItemCount} öğe bulundu',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          if (_visibleStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._visibleStats.map((s) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (_, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - val)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.icon, color: s.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(s.detail, style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_outline, color: s.color, size: 16),
                  ],
                ),
              ),
            )),
          ],
          if (_statsRevealed) ...[
            const SizedBox(height: 14),
            if (!isPremium && hasFreeClean)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Haftalık ücretsiz temizleme hakkınız var!',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                widget.ref.read(scanResultProvider.notifier).startScan();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tekrar Tara'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanStat {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  const _ScanStat(this.icon, this.title, this.detail, this.color);
}

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
    final allItems = widget.groups.expand((g) => g).toList();
    final allSelected = _selected.length == allItems.length && allItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraflar'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll(allItems.map((e) => e.id));
                }
              });
            },
            child: Text(
              allSelected ? 'Seçimi Kaldır' : 'Tümünü Seç',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (totalSelected > 0)
            TextButton.icon(
              onPressed: () => _deleteSelected(),
              icon: const Icon(Icons.delete, color: AppColors.danger),
              label: Text(
                '$totalSelected sil',
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
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
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
              Divider(
                  height: 24,
                  color: AppColors.textTertiary.withValues(alpha: 0.3)),
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
        content:
            Text('${_selected.length} fotoğraf silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
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

    final allSelected = _selected.length == widget.items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll(widget.items.map((e) => e.id));
                }
              });
            },
            child: Text(
              allSelected ? 'Seçimi Kaldır' : 'Hepsini Seç',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: () => _deleteSelected(),
              icon: const Icon(Icons.delete, color: AppColors.danger),
              label: Text(
                '${_selected.length} sil',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
      body: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
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
          child:
              Icon(Icons.image, color: AppColors.textTertiary, size: 24),
        ),
      );
    }
    return Image.memory(_data!, fit: BoxFit.cover);
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
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
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
            child: const Icon(Icons.cached,
                color: AppColors.tertiary, size: 24),
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
