import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/offerings_load.dart';
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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bolt, color: AppColors.background, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Oxyn Plus',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tüm özelliklerin kilidini aç',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    const _CompactFeatures(),
                    const SizedBox(height: 20),
                    offeringsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, s) => _FallbackPricing(
                        ref: ref,
                        failure: OfferingsFailure.unknown,
                      ),
                      data: (result) {
                        if (result.hasPackages) {
                          return _PackageList(
                            packages: result.packages,
                            ref: ref,
                          );
                        }
                        return _FallbackPricing(
                          ref: ref,
                          failure: result.failure,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ref.read(subscriptionStatusProvider.notifier).restore();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: const Text(
                        'Satın Alımları Geri Yükle',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/privacy'),
                          child: const Text(
                            'Gizlilik Politikası',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context.push('/terms'),
                          child: const Text(
                            'Kullanım Şartları',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Abonelik otomatik yenilenir. İstediğiniz zaman mağaza ayarlarından iptal edebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 10, height: 1.3),
                    ),
                    const SizedBox(height: 16),
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

class _CompactFeatures extends StatelessWidget {
  const _CompactFeatures();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          _FeatureRow(Icons.all_inclusive, t.plusFeatureClean),
          _FeatureRow(Icons.health_and_safety, t.plusFeatureDoctor),
          _FeatureRow(Icons.battery_full, t.plusFeatureBatteryReport),
          _FeatureRow(Icons.folder_open, t.plusFeatureLargeFiles),
          _FeatureRow(Icons.palette, t.plusFeatureStyles),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
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
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Package package;
  final WidgetRef ref;
  const _PricingCard({required this.package, required this.ref});

  String _unitLabel(PeriodUnit unit) {
    switch (unit) {
      case PeriodUnit.day:
        return 'gün';
      case PeriodUnit.week:
        return 'hafta';
      case PeriodUnit.month:
        return 'ay';
      case PeriodUnit.year:
        return 'yıl';
      case PeriodUnit.unknown:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final isWeekly = package.packageType == PackageType.weekly;
    final isAnnual = package.packageType == PackageType.annual;

    // Only advertise a free trial / intro offer when the store product
    // actually provides one. Claiming "3 gün ücretsiz deneme" on a product
    // without a configured trial is a deceptive purchase experience and
    // violates store policy.
    final intro = product.introductoryPrice;
    final hasFreeTrial = intro != null && intro.price == 0;
    final String? subtitleText = hasFreeTrial
        ? '${intro.periodNumberOfUnits} ${_unitLabel(intro.periodUnit)} ücretsiz deneme'
        : (isAnnual ? 'Yıllık fatura' : null);

    return GestureDetector(
      onTap: () async {
        try {
          await ref.read(subscriptionStatusProvider.notifier).purchase(package);
          if (context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Satın alma iptal edildi')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWeekly ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
                          fontSize: 14,
                        ),
                      ),
                      if (isWeekly) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Popüler',
                            style: TextStyle(color: AppColors.background, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      if (isAnnual) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Tasarruf',
                            style: TextStyle(color: AppColors.background, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitleText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              product.priceString,
              style: TextStyle(
                fontSize: 16,
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

/// Shown only when store packages could not be loaded. No hardcoded prices.
class _FallbackPricing extends StatelessWidget {
  final WidgetRef ref;
  final OfferingsFailure failure;
  const _FallbackPricing({required this.ref, required this.failure});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final detail = switch (failure) {
      OfferingsFailure.testStoreEmpty => t.offeringsTestStore,
      OfferingsFailure.storeUnavailable => t.offeringsStoreUnavailable,
      OfferingsFailure.empty => t.offeringsEmpty,
      OfferingsFailure.notReady => t.offeringsNotReady,
      OfferingsFailure.unknown || OfferingsFailure.none => t.offeringsUnknown,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 12),
          Text(
            t.offeringsLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ref.invalidate(offeringsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                t.tryAgain,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
