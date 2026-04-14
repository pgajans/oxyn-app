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
}
