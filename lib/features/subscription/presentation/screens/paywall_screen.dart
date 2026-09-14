import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/offerings_load.dart';
import '../../domain/subscription_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If the user is already premium, never show an upsell — celebrate instead.
    if (ref.watch(isPremiumProvider)) {
      return const _AlreadyPremiumView();
    }

    final offeringsAsync = ref.watch(offeringsProvider);
    final t = AppLocalizations.of(context)!;

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
                    Text(
                      t.unlockAllFeatures,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    const _EmotionHero(),
                    const SizedBox(height: 16),
                    const _EmotionBenefits(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.tertiary, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.paywallFreeTasteNote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.tertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        feedback.tap();
                        ref.read(subscriptionStatusProvider.notifier).restore();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: Text(
                        t.restorePurchases,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/privacy'),
                          child: Text(
                            t.privacyPolicy,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context.push('/terms'),
                          child: Text(
                            t.termsOfUse,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.subscriptionAutoRenewNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          height: 1.3),
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

/// Shown instead of the paywall when the user is already an Oxyn Plus member.
class _AlreadyPremiumView extends StatefulWidget {
  const _AlreadyPremiumView();

  @override
  State<_AlreadyPremiumView> createState() => _AlreadyPremiumViewState();
}

class _AlreadyPremiumViewState extends State<_AlreadyPremiumView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    // celebratory feedback
    WidgetsBinding.instance.addPostFrameCallback((_) => feedback.success());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _manage() async {
    feedback.tap();
    final uri = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/account/subscriptions')
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
                  feedback.tap();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _ctrl,
                          curve: Curves.elasticOut,
                        ),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.tertiary,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.tertiary
                                    .withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium,
                              color: Colors.white, size: 52),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        t.alreadyPremiumTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.alreadyPremiumDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _manage,
                          icon: const Icon(Icons.settings, size: 18),
                          label: Text(t.manageYourSubscription),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emotional hero banner: sells the *feeling*, not a dry feature list.
class _EmotionHero extends StatefulWidget {
  const _EmotionHero();

  @override
  State<_EmotionHero> createState() => _EmotionHeroState();
}

class _EmotionHeroState extends State<_EmotionHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.15 + _pulse.value * 0.25;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.tertiaryDark, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.tertiary.withValues(alpha: glow),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          const Icon(Icons.spa_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 10),
          Text(
            t.paywallHeroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.paywallHeroSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Benefit list phrased as feelings/outcomes, with a staggered entrance.
class _EmotionBenefits extends StatefulWidget {
  const _EmotionBenefits();

  @override
  State<_EmotionBenefits> createState() => _EmotionBenefitsState();
}

class _EmotionBenefitsState extends State<_EmotionBenefits>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = <_Benefit>[
      _Benefit(Icons.block, AppColors.danger, t.paywallBenefitAdFreeTitle,
          t.paywallBenefitAdFreeDesc),
      _Benefit(Icons.all_inclusive, AppColors.secondary,
          t.paywallBenefitCleanTitle, t.paywallBenefitCleanDesc),
      _Benefit(Icons.battery_charging_full, AppColors.success,
          t.paywallBenefitBatteryTitle, t.paywallBenefitBatteryDesc),
      _Benefit(Icons.palette, AppColors.tertiary,
          t.paywallBenefitStyleTitle, t.paywallBenefitStyleDesc),
      _Benefit(Icons.health_and_safety, AppColors.primary,
          t.paywallBenefitDoctorTitle, t.paywallBenefitDoctorDesc),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final start = i / items.length * 0.6;
                final v = Curves.easeOutBack.transform(
                  ((_ctrl.value - start) / (1 - start)).clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - v)),
                    child: child,
                  ),
                );
              },
              child: _BenefitRow(items[i]),
            ),
        ],
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Benefit(this.icon, this.color, this.title, this.desc);
}

class _BenefitRow extends StatelessWidget {
  final _Benefit benefit;
  const _BenefitRow(this.benefit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: benefit.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(benefit.icon, color: benefit.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
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

  String _unitLabel(AppLocalizations t, PeriodUnit unit) {
    switch (unit) {
      case PeriodUnit.day:
        return t.unitDay;
      case PeriodUnit.week:
        return t.unitWeek;
      case PeriodUnit.month:
        return t.unitMonth;
      case PeriodUnit.year:
        return t.unitYear;
      case PeriodUnit.unknown:
        return '';
    }
  }

  /// Clean plan label. Google Play automatically appends the app name in
  /// parentheses to the subscription title returned by the Billing API, e.g.
  /// "Oxyn Plus Yearly (Oxyn: Battery & Storage Care)". This overflows and
  /// collides with the price, and it cannot be removed from the store side.
  /// We strip the trailing parenthetical so only the plan name remains
  /// (e.g. "Oxyn Plus Yearly"). Works the same on iOS.
  String _planLabel() {
    final raw = package.storeProduct.title;
    final stripped = raw.replaceFirst(RegExp(r'\s*\(.*\)\s*$'), '').trim();
    return stripped.isEmpty ? raw : stripped;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
        ? t.freeTrialLabel(
            intro.periodNumberOfUnits, _unitLabel(t, intro.periodUnit))
        : (isAnnual ? t.annualBilling : null);

    return GestureDetector(
      onTap: () async {
        feedback.tap();
        try {
          await ref.read(subscriptionStatusProvider.notifier).purchase(package);
          feedback.success();
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
              SnackBar(content: Text(t.purchaseCancelled)),
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
                      Flexible(
                        child: Text(
                          _planLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
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
            const SizedBox(width: 10),
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
