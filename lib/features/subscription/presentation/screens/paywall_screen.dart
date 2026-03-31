import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/subscription_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Oxyn logo/icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: AppColors.background,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Oxyn Plus',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Tüm özelliklerin kilidini aç',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Features list
                    const _FeaturesList(),
                    const SizedBox(height: AppSpacing.xl),
                    // Pricing
                    offeringsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, s) => _FallbackPricing(ref: ref),
                      data: (packages) {
                        if (packages.isEmpty) {
                          return _FallbackPricing(ref: ref);
                        }
                        return _PackageList(packages: packages, ref: ref);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Restore purchases
                    TextButton(
                      onPressed: () {
                        ref.read(subscriptionStatusProvider.notifier).restore();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Satın Alımları Geri Yükle',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Legal links
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Gizlilik Politikası',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Kullanım Şartları',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Abonelik otomatik yenilenir. İstediğiniz zaman mağaza ayarlarından iptal edebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  const _FeaturesList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FeatureRow(
          icon: Icons.all_inclusive,
          text: 'Sınırsız fotoğraf ve dosya temizliği',
        ),
        _FeatureRow(
          icon: Icons.bolt,
          text: 'Tüm şarj animasyonları',
        ),
        _FeatureRow(
          icon: Icons.widgets,
          text: 'Tüm widget stilleri',
        ),
        _FeatureRow(
          icon: Icons.block,
          text: 'Reklamları kaldır',
        ),
        _FeatureRow(
          icon: Icons.battery_full,
          text: 'Detaylı batarya raporu',
        ),
        _FeatureRow(
          icon: Icons.folder_open,
          text: 'Büyük dosya bulucu tam erişim',
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PackageList extends StatelessWidget {
  final List<Package> packages;
  final WidgetRef ref;

  const _PackageList({required this.packages, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final pkg in packages) ...[
          _PricingCard(package: pkg, ref: ref),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Package package;
  final WidgetRef ref;

  const _PricingCard({required this.package, required this.ref});

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final isWeekly = package.packageType == PackageType.weekly;

    return GestureDetector(
      onTap: () async {
        try {
          await ref.read(subscriptionStatusProvider.notifier).purchase(package);
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Satın alma iptal edildi')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isWeekly ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWeekly ? AppColors.primary : AppColors.surfaceLight,
            width: isWeekly ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      if (isWeekly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Popüler',
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3 gün ücretsiz deneme',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              product.priceString,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isWeekly ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackPricing extends StatelessWidget {
  final WidgetRef ref;

  const _FallbackPricing({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FallbackCard(
          title: 'Haftalık',
          price: '\$2.99/hafta',
          subtitle: '3 gün ücretsiz deneme',
          isPopular: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abonelik sistemi yapılandırılıyor, yakında aktif olacak'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _FallbackCard(
          title: 'Aylık',
          price: '\$6.99/ay',
          subtitle: 'En çok tercih edilen',
          isPopular: false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abonelik sistemi yapılandırılıyor, yakında aktif olacak'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _FallbackCard(
          title: 'Yıllık',
          price: '\$49.99/yıl',
          subtitle: '%58 tasarruf',
          isPopular: false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abonelik sistemi yapılandırılıyor, yakında aktif olacak'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FallbackCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final bool isPopular;
  final VoidCallback onTap;

  const _FallbackCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPopular ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.surfaceLight,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Popüler',
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isPopular ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
