enum SubscriptionTier { free, plus, pro }

class SubscriptionStatus {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expiresAt;
  final String? productId;
  final bool isTrialActive;

  const SubscriptionStatus({
    required this.tier,
    required this.isActive,
    this.expiresAt,
    this.productId,
    this.isTrialActive = false,
  });

  factory SubscriptionStatus.free() => const SubscriptionStatus(
        tier: SubscriptionTier.free,
        isActive: false,
      );

  bool get isFree => tier == SubscriptionTier.free;
  bool get isPlus => tier == SubscriptionTier.plus;
  bool get isPro => tier == SubscriptionTier.pro;
  bool get isPremium => isPlus || isPro;

  // Feature access checks
  bool get hasUnlimitedCleaning => isPremium;
  bool get hasAllAnimations => isPremium;
  bool get hasAllWidgets => isPro;
  bool get isAdFree => isPremium;
  bool get hasDetailedBatteryReport => isPremium;
  bool get hasLargeFileFullAccess => isPremium;

  int get dailyCleanLimit => isFree ? 25 : -1; // -1 = unlimited

  String get tierName {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Ücretsiz';
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }
}
