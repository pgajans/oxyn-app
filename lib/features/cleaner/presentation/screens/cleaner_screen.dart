import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../domain/storage_info.dart';
import '../../domain/storage_provider.dart';

class CleanerScreen extends ConsumerWidget {
  const CleanerScreen({super.key});

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
            // Scan section
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
            // Cleaning categories
            _CleaningCategory(
              icon: Icons.photo_library,
              title: 'Benzer Fotoğraflar',
              subtitle: 'Galeriyi tarayarak benzer fotoğrafları bul',
              size: '—',
              color: AppColors.secondary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Fotoğraf tarama özelliği yakında aktif olacak'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _CleaningCategory(
              icon: Icons.file_present,
              title: 'Büyük Dosyalar',
              subtitle: '50MB üzeri dosyalar',
              size: '—',
              color: AppColors.danger,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Büyük dosya tarama özelliği yakında aktif olacak'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _CleaningCategory(
              icon: Icons.screenshot,
              title: 'Ekran Görüntüleri',
              subtitle: 'Eski ekran görüntülerini temizle',
              size: '—',
              color: AppColors.primary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Ekran görüntüsü tarama özelliği yakında aktif olacak'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _CacheCategory(ref: ref),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  final ScanResult scan;
  final WidgetRef ref;

  const _ScanResultCard({required this.scan, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasCacheToClear = scan.cacheBytes > 0;

    return OxynCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            hasCacheToClear ? Icons.cleaning_services : Icons.check_circle,
            color: hasCacheToClear ? AppColors.secondary : AppColors.success,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            hasCacheToClear
                ? 'Temizlenebilir: ${StorageInfo.formatBytes(scan.cacheBytes)}'
                : 'Cihazın temiz!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasCacheToClear) ...[
            const SizedBox(height: 4),
            const Text(
              'Uygulama önbelleği temizlenebilir',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final cleaned = await ref
                      .read(scanResultProvider.notifier)
                      .cleanCache();
                  if (context.mounted) {
                    final mb =
                        (cleaned / (1024 * 1024)).toStringAsFixed(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$mb MB önbellek temizlendi!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                    ref.invalidate(storageInfoProvider);
                  }
                },
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Temizle'),
              ),
            ),
          ],
          if (!hasCacheToClear) ...[
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
