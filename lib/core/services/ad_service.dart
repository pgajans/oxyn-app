import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  final DateTime _sessionStart = DateTime.now();
  DateTime? _lastInterstitialShown;
  int _interstitialsThisSession = 0;

  static const Duration _minInterstitialGap = Duration(seconds: 90);
  static const Duration _sessionInitialGrace = Duration(seconds: 60);
  static const int _maxInterstitialsPerSession = 5;

  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get _isIos => !kIsWeb && Platform.isIOS;

  static bool get isAdsAvailable {
    if (_isAndroid) return true;
    if (_isIos) return AppConstants.admobIosAppId.isNotEmpty;
    return false;
  }

  String get bannerAdUnitId {
    if (kDebugMode) return _testBanner;
    return _isIos
        ? AppConstants.admobIosBannerId
        : AppConstants.admobAndroidBannerId;
  }

  String get _interstitialId {
    if (kDebugMode) return _testInterstitial;
    return _isIos
        ? AppConstants.admobIosInterstitialId
        : AppConstants.admobAndroidInterstitialId;
  }

  String get _rewardedId {
    if (kDebugMode) return _testRewarded;
    return _isIos
        ? AppConstants.admobIosRewardedId
        : AppConstants.admobAndroidRewardedId;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!isAdsAvailable) {
      _initialized = true;
      debugPrint('AdMob skipped: Android only for now');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdMob initialized');
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdMob init error: $e');
      _initialized = true;
    }
  }

  void _loadInterstitial() {
    if (!_initialized || !isAdsAvailable) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('Interstitial failed to load: $error');
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  Future<bool> showInterstitial() async {
    if (!_initialized || !isAdsAvailable) return false;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    await ad.show();
    return true;
  }

  Future<bool> maybeShowInterstitial({required bool isPremium}) async {
    if (isPremium) return false;
    if (!_initialized || !isAdsAvailable) return false;

    final now = DateTime.now();
    if (now.difference(_sessionStart) < _sessionInitialGrace) return false;
    if (_interstitialsThisSession >= _maxInterstitialsPerSession) return false;
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < _minInterstitialGap) {
      return false;
    }

    final shown = await showInterstitial();
    if (shown) {
      _lastInterstitialShown = now;
      _interstitialsThisSession++;
    }
    return shown;
  }

  void _loadRewarded() {
    if (!_initialized || !isAdsAvailable) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewarded = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewarded = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          debugPrint('Rewarded failed to load: $error');
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  Future<bool> showRewarded({required VoidCallback onRewarded}) async {
    if (!_initialized || !isAdsAvailable) return false;
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    await ad.show(onUserEarnedReward: (_, __) => onRewarded());
    return true;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    _initialized = false;
  }
}

enum AdRewardType {
  extraCleaningQuota,
  tryPremiumAnimation,
  extraScanCategory,
}
