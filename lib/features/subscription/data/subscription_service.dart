import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../domain/subscription_status.dart';

class SubscriptionService {
  // Production key'ler RevenueCat dashboard'dan alınacak
  // Test key'ler sadece debug modda çalışır, release'de RevenueCat devre dışı kalır
  static const _apiKeyiOS = 'test_TzkrDTMSSUVFIReOIcxWQsVUWkr';
  static const _apiKeyAndroid = 'test_TzkrDTMSSUVFIReOIcxWQsVUWkr';

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static bool get _isTestKey =>
      _apiKeyiOS.startsWith('test_') || _apiKeyAndroid.startsWith('test_');

  Future<void> initialize() async {
    if (kReleaseMode && _isTestKey) {
      debugPrint('RevenueCat skipped: test key in release mode');
      return;
    }

    try {
      await Purchases.setLogLevel(
          kReleaseMode ? LogLevel.warn : LogLevel.debug);

      PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_apiKeyiOS);
      } else {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      }

      await Purchases.configure(configuration);
      _initialized = true;
      debugPrint('RevenueCat initialized');
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    if (!_initialized) return SubscriptionStatus.free();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _mapToStatus(customerInfo);
    } catch (e) {
      debugPrint('getSubscriptionStatus error: $e');
      return SubscriptionStatus.free();
    }
  }

  Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (e) {
      debugPrint('getOfferings error: $e');
      return [];
    }
  }

  Future<SubscriptionStatus> purchase(Package package) async {
    if (!_initialized) return SubscriptionStatus.free();
    try {
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      return _mapToStatus(result.customerInfo);
    } catch (e) {
      debugPrint('purchase error: $e');
      rethrow;
    }
  }

  Future<SubscriptionStatus> restorePurchases() async {
    if (!_initialized) return SubscriptionStatus.free();
    try {
      final customerInfo = await Purchases.restorePurchases();
      return _mapToStatus(customerInfo);
    } catch (e) {
      debugPrint('restorePurchases error: $e');
      return SubscriptionStatus.free();
    }
  }

  SubscriptionStatus _mapToStatus(CustomerInfo info) {
    final entitlements = info.entitlements.active;

    if (entitlements.containsKey('pro')) {
      final ent = entitlements['pro']!;
      return SubscriptionStatus(
        tier: SubscriptionTier.pro,
        isActive: true,
        expiresAt: ent.expirationDate != null
            ? DateTime.tryParse(ent.expirationDate!)
            : null,
        productId: ent.productIdentifier,
        isTrialActive: ent.periodType == PeriodType.trial,
      );
    }

    if (entitlements.containsKey('plus')) {
      final ent = entitlements['plus']!;
      return SubscriptionStatus(
        tier: SubscriptionTier.plus,
        isActive: true,
        expiresAt: ent.expirationDate != null
            ? DateTime.tryParse(ent.expirationDate!)
            : null,
        productId: ent.productIdentifier,
        isTrialActive: ent.periodType == PeriodType.trial,
      );
    }

    return SubscriptionStatus.free();
  }
}
