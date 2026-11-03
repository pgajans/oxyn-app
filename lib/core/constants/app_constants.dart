class AppConstants {
  AppConstants._();

  static const String appName = 'Oxyn';
  static const String appTagline = 'Breathe life into your phone';

  // Free tier limits
  static const int freePhotoCleanLimit = 25;
  static const int rewardedExtraCleanCount = 10;
  static const int freeAnimationCount = 3;
  static const int freeWidgetStyleCount = 1;

  // Scan
  static const Duration scanDuration = Duration(seconds: 60);
  static const int largeFileThresholdMB = 50;

  // Battery
  static const int chargeAlarmPercent = 80;

  // Animation
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration scoreAnimation = Duration(milliseconds: 1500);
  static const Duration pulseAnimation = Duration(milliseconds: 800);

  // Paywall
  static const String weeklyProductId = 'oxyn_plus_weekly';
  static const String monthlyPlusProductId = 'oxyn_plus_monthly';
  static const String monthlyProProductId = 'oxyn_pro_monthly';
  static const String yearlyProProductId = 'oxyn_pro_yearly';

  static const List<String> subscriptionProductIds = [
    weeklyProductId,
    monthlyPlusProductId,
    monthlyProProductId,
    yearlyProProductId,
  ];

  // AdMob (public client IDs). Debug builds use Google test units.
  static const String admobAndroidAppId =
      'ca-app-pub-5166393645234481~7250319452';
  static const String admobAndroidBannerId =
      'ca-app-pub-5166393645234481/9736881997';
  static const String admobAndroidInterstitialId =
      'ca-app-pub-5166393645234481/7603699363';
  static const String admobAndroidRewardedId =
      'ca-app-pub-5166393645234481/1716947869';

  static const String admobIosAppId =
      'ca-app-pub-5166393645234481~2702726473';
  static const String admobIosBannerId =
      'ca-app-pub-5166393645234481/6836965492';
  static const String admobIosInterstitialId =
      'ca-app-pub-5166393645234481/9894820788';
  static const String admobIosRewardedId =
      'ca-app-pub-5166393645234481/7268657440';
}
