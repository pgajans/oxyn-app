import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../../features/subscription/domain/subscription_provider.dart';

/// Self-hiding AdMob banner.
///
/// Hidden for premium users and when ads are not available (iOS / failed init).
/// Uses an anchored adaptive size so it never covers interactive content.
class OxynBannerAd extends ConsumerStatefulWidget {
  const OxynBannerAd({super.key});

  @override
  ConsumerState<OxynBannerAd> createState() => _OxynBannerAdState();
}

class _OxynBannerAdState extends ConsumerState<OxynBannerAd> {
  BannerAd? _banner;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (_banner != null) return;
    if (ref.read(isPremiumProvider) || !AdService.isAdsAvailable) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          width,
        ) ??
        AdSize.banner;

    final banner = BannerAd(
      adUnitId: AdService().bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _banner = null;
              _ready = false;
            });
          }
        },
      ),
    );
    _banner = banner;
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final banner = _banner;
    if (isPremium || !AdService.isAdsAvailable || !_ready || banner == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
