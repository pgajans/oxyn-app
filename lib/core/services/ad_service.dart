import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _initialized = false;
  VoidCallback? _pendingRewardCallback;

  static const _sdkKey = 'YOUR_APPLOVIN_SDK_KEY';

  static const _interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
  static const _rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
  static const _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final config = await AppLovinMAX.initialize(_sdkKey);
      if (config == null) {
        debugPrint('AppLovin MAX init returned null');
        _initialized = true;
        return;
      }

      _setupInterstitialListeners();
      _setupRewardedListeners();

      _initialized = true;
      debugPrint('AdService initialized');

      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdService init error: $e');
      _initialized = true;
    }
  }

  // --- Interstitial ---

  void _setupInterstitialListeners() {
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (_) {
        debugPrint('Interstitial ad loaded');
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        Future.delayed(const Duration(seconds: 30), _loadInterstitial);
      },
      onAdDisplayedCallback: (_) {},
      onAdDisplayFailedCallback: (adUnitId, error) {
        _loadInterstitial();
      },
      onAdClickedCallback: (_) {},
      onAdHiddenCallback: (_) {
        _loadInterstitial();
      },
    ));
  }

  void _loadInterstitial() {
    AppLovinMAX.loadInterstitial(_interstitialAdUnitId);
  }

  Future<bool> showInterstitial() async {
    if (!_initialized) return false;

    final ready = await AppLovinMAX.isInterstitialReady(_interstitialAdUnitId);
    if (ready ?? false) {
      AppLovinMAX.showInterstitial(_interstitialAdUnitId);
      return true;
    }

    debugPrint('Interstitial ad not ready');
    return false;
  }

  // --- Rewarded ---

  void _setupRewardedListeners() {
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
      onAdLoadedCallback: (_) {
        debugPrint('Rewarded ad loaded');
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        Future.delayed(const Duration(seconds: 30), _loadRewarded);
      },
      onAdDisplayedCallback: (_) {},
      onAdDisplayFailedCallback: (adUnitId, error) {
        _loadRewarded();
      },
      onAdClickedCallback: (_) {},
      onAdHiddenCallback: (_) {
        _loadRewarded();
      },
      onAdReceivedRewardCallback: (adUnitId, reward) {
        _pendingRewardCallback?.call();
        _pendingRewardCallback = null;
      },
    ));
  }

  void _loadRewarded() {
    AppLovinMAX.loadRewardedAd(_rewardedAdUnitId);
  }

  Future<bool> showRewarded({required VoidCallback onRewarded}) async {
    if (!_initialized) return false;

    final ready = await AppLovinMAX.isRewardedAdReady(_rewardedAdUnitId);
    if (ready ?? false) {
      _pendingRewardCallback = onRewarded;
      AppLovinMAX.showRewardedAd(_rewardedAdUnitId);
      return true;
    }

    debugPrint('Rewarded ad not ready');
    return false;
  }

  // --- Banner ---

  String get bannerAdUnitId => _bannerAdUnitId;

  void dispose() {
    _initialized = false;
    _pendingRewardCallback = null;
  }
}

enum AdRewardType {
  extraCleaningQuota,
  tryPremiumAnimation,
  extraScanCategory,
}
