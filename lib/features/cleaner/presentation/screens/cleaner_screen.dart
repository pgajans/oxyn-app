import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';

class CleanerScreen extends StatelessWidget {
  const CleanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temizlik')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            // Storage overview
            const _StorageOverview(),
            const SizedBox(height: AppSpacing.lg),
            // Cleaning categories
            const _CleaningCategory(
              icon: Icons.photo_library,
              title: 'Benzer Fotoğraflar',
              subtitle: '847 benzer fotoğraf bulundu',
              size: '1.8 GB',
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const _CleaningCategory(
              icon: Icons.file_present,
              title: 'Büyük Dosyalar',
              subtitle: '12 dosya 50MB üzeri',
              size: '2.3 GB',
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            const _CleaningCategory(
              icon: Icons.screenshot,
              title: 'Ekran Görüntüleri',
              subtitle: '234 ekran görüntüsü',
              size: '890 MB',
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            const _CleaningCategory(
              icon: Icons.cached,
              title: 'Önbellek',
              subtitle: 'Uygulama önbelleği',
              size: '320 MB',
              color: AppColors.tertiary,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StorageOverview extends StatelessWidget {
  const _StorageOverview();

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Temizlenebilir Alan',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '5.3 GB',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: 34, child: ColoredBox(color: AppColors.secondary)),
                  Expanded(flex: 43, child: ColoredBox(color: AppColors.danger)),
                  Expanded(flex: 17, child: ColoredBox(color: AppColors.primary)),
                  Expanded(flex: 6, child: ColoredBox(color: AppColors.tertiary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(color: AppColors.secondary, label: 'Fotoğraf'),
              _LegendItem(color: AppColors.danger, label: 'Dosyalar'),
              _LegendItem(color: AppColors.primary, label: 'Ekran G.'),
              _LegendItem(color: AppColors.tertiary, label: 'Önbellek'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
      onTap: () {
        // TODO: Navigate to detail screen
      },
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
          Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
