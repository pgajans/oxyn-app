import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ad_service.dart';
import '../../features/subscription/domain/subscription_provider.dart';

/// A safe, self-hiding banner ad.
///
/// - Shows nothing for premium (ad-free) users.
/// - Shows nothing when AppLovin keys are not configured (placeholder),
///   so the app behaves normally before ads are wired up.
/// - Anchored, fixed-height banner that never covers interactive content.
class OxynBannerAd extends ConsumerWidget {
  const OxynBannerAd({super.key});

  static const double _bannerHeight = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final adUnitId = AdService().bannerAdUnitId;

    if (isPremium || !AdService.isAdsAvailable || adUnitId.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: _bannerHeight,
        width: double.infinity,
        child: MaxAdView(
          adUnitId: adUnitId,
          adFormat: AdFormat.banner,
        ),
      ),
    );
  }
}
