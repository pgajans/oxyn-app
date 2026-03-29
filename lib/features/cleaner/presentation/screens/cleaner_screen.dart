import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
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
            // Storage overview
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
            // Scan button
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
                if (scan.totalItemCount == 0) {
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
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // Cleaning categories
            const _CleaningCategory(
              icon: Icons.photo_library,
              title: 'Benzer Fotoğraflar',
              subtitle: 'Taranmayı bekliyor',
              size: '—',
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const _CleaningCategory(
              icon: Icons.file_present,
              title: 'Büyük Dosyalar',
              subtitle: '50MB üzeri dosyalar',
              size: '—',
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            const _CleaningCategory(
              icon: Icons.screenshot,
              title: 'Ekran Görüntüleri',
              subtitle: 'Taranmayı bekliyor',
              size: '—',
              color: AppColors.primary,
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

  const _CleaningCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: () {},
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      onTap: () {
        // TODO: Clear app cache with confirmation
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cached, color: AppColors.tertiary, size: 24),
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
