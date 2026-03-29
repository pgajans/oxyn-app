import 'package:flutter/foundation.dart';

/// AppLovin MAX Reklam Servisi
///
/// applovin_max paketi projeye eklendiğinde tam entegrasyon yapılacak.
/// Şu an servis iskeleti ve mantık hazır durumda.
///
/// Entegrasyon adımları:
/// 1. pubspec.yaml'a applovin_max ekle
/// 2. AppLovin dashboard'dan SDK key al
/// 3. AdMob, Meta, Unity Ads bidder'larını ekle
/// 4. Ad unit ID'lerini yapılandır
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _initialized = false;

  // Ad Unit IDs - AppLovin dashboard'dan alınacak
  static const _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';

  Future<void> initialize() async {
    if (_initialized) return;

    // AppLovin MAX SDK initialization:
    // await AppLovinMAX.initialize(sdkKey);
    // await AppLovinMAX.setHasUserConsent(true);
    // await AppLovinMAX.setIsAgeRestrictedUser(false);

    _initialized = true;
    debugPrint('AdService initialized');

    _loadRewarded();
    _loadInterstitial();
  }

  // --- Rewarded Video ---

  void _loadRewarded() {
    // AppLovinMAX.loadRewardedAd(_rewardedAdUnitId);
    debugPrint('Loading rewarded ad...');
  }

  /// Rewarded video göster
  /// Kullanıcı tamamlarsa [onRewarded] çağrılır
  Future<bool> showRewarded({required VoidCallback onRewarded}) async {
    if (!_initialized) return false;

    // if (await AppLovinMAX.isRewardedAdReady(_rewardedAdUnitId)) {
    //   AppLovinMAX.showRewardedAd(_rewardedAdUnitId);
    //   // Listen for reward callback
    //   onRewarded();
    //   return true;
    // }

    debugPrint('Rewarded ad not ready');
    return false;
  }

  // --- Interstitial ---

  void _loadInterstitial() {
    // AppLovinMAX.loadInterstitial(_interstitialAdUnitId);
    debugPrint('Loading interstitial ad...');
  }

  /// Interstitial göster - SADECE temizlik tamamlandı sonrası
  Future<bool> showInterstitial() async {
    if (!_initialized) return false;

    // if (await AppLovinMAX.isInterstitialReady(_interstitialAdUnitId)) {
    //   AppLovinMAX.showInterstitial(_interstitialAdUnitId);
    //   return true;
    // }

    debugPrint('Interstitial ad not ready');
    return false;
  }

  // --- Banner ---

  /// Banner widget'ı için ad unit ID döndürür
  String get bannerAdUnitId => _bannerAdUnitId;

  /// Tüm reklamları temizle
  void dispose() {
    _initialized = false;
    debugPrint('AdService disposed');
  }
}

/// Rewarded video sonrası kullanıcıya verilecek ödüller
enum AdRewardType {
  extraCleaningQuota,    // +10 ek temizlik hakkı
  tryPremiumAnimation,   // 24 saat premium animasyon deneme
  extraScanCategory,     // +1 ek kategori taraması
}
