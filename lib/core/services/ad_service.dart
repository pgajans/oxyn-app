import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _initialized = false;
  VoidCallback? _pendingRewardCallback;

  // --- Interstitial frequency capping (Play "Disruptive Ads" safety) ---
  final DateTime _sessionStart = DateTime.now();
  DateTime? _lastInterstitialShown;
  int _interstitialsThisSession = 0;

  /// Minimum time between two interstitials.
  static const Duration _minInterstitialGap = Duration(seconds: 90);

  /// No interstitials during the first moments of a session.
  static const Duration _sessionInitialGrace = Duration(seconds: 60);

  /// Hard cap on interstitials per app session.
  static const int _maxInterstitialsPerSession = 5;

  static const _sdkKey = String.fromEnvironment(
    'APPLOVIN_SDK_KEY',
    defaultValue: '',
  );

  static const _interstitialAdUnitId = String.fromEnvironment(
    'APPLOVIN_INTERSTITIAL_ID',
    defaultValue: '',
  );
  static const _rewardedAdUnitId = String.fromEnvironment(
    'APPLOVIN_REWARDED_ID',
    defaultValue: '',
  );
  static const _bannerAdUnitId = String.fromEnvironment(
    'APPLOVIN_BANNER_ID',
    defaultValue: '',
  );

  static bool get isAdsAvailable => !_isPlaceholderKey;

  static bool get _isPlaceholderKey =>
      _sdkKey.isEmpty || _sdkKey.startsWith('YOUR_');

  Future<void> initialize() async {
    if (_initialized) return;

    if (_isPlaceholderKey) {
      debugPrint('AppLovin skipped: placeholder SDK key');
      _initialized = true;
      return;
    }

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
    if (!_initialized || _isPlaceholderKey) return false;

    final ready = await AppLovinMAX.isInterstitialReady(_interstitialAdUnitId);
    if (ready ?? false) {
      AppLovinMAX.showInterstitial(_interstitialAdUnitId);
      return true;
    }

    debugPrint('Interstitial ad not ready');
    return false;
  }

  /// Premium-aware, frequency-capped interstitial. Use this from screens
  /// instead of [showInterstitial] so we never spam ads or show them to
  /// premium (ad-free) users.
  Future<bool> maybeShowInterstitial({required bool isPremium}) async {
    if (isPremium) return false;
    if (!_initialized || _isPlaceholderKey) return false;

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
    if (!_initialized || _isPlaceholderKey) return false;

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
