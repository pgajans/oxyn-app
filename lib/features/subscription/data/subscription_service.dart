import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/offerings_load.dart';
import '../domain/subscription_status.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  static const _apiKeyiOS = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: 'test_TzkrDTMSSUVFIReOIcxWQsVUWkr',
  );
  static const _apiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: 'goog_FcjENVZJSseGJJQvdBjuFvhEZkp',
  );

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static bool get isUsingTestStoreKey {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _apiKeyiOS.isEmpty || _apiKeyiOS.startsWith('test_');
    }
    return _apiKeyAndroid.isEmpty || _apiKeyAndroid.startsWith('test_');
  }

  static bool get _isTestKey => isUsingTestStoreKey;

  Future<void> initialize() async {
    if (_initialized) return;

    // CRITICAL: RevenueCat SDK intentionally crashes (assertionFailure) in release
    // builds when a test/sandbox API key (prefix `test_`) is detected. To prevent
    // a hard crash on launch, we skip Purchases.configure entirely when this
    // unsafe combination is present. Without configure, all entitlement checks
    // return free tier, which is the safest default.
    if (_isTestKey && kReleaseMode) {
      debugPrint(
          'RevenueCat: test key in release build detected, SKIPPING initialization to avoid SDK assertion crash');
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

  Future<OfferingsLoadResult> getOfferings() async {
    await initialize();
    if (!_initialized) {
      return OfferingsLoadResult(
        packages: const [],
        failure: _isTestKey && kReleaseMode
            ? OfferingsFailure.notReady
            : OfferingsFailure.notReady,
      );
    }

    try {
      final offerings = await Purchases.getOfferings();
      var packages = _packagesFrom(offerings);
      if (packages.isEmpty) {
        packages = await _packagesFromProductIds();
      }
      if (packages.isEmpty) {
        return OfferingsLoadResult(
          packages: const [],
          failure: _isTestKey
              ? OfferingsFailure.testStoreEmpty
              : OfferingsFailure.empty,
        );
      }
      return OfferingsLoadResult(packages: packages);
    } catch (e) {
      debugPrint('getOfferings error: $e');
      return OfferingsLoadResult(
        packages: const [],
        failure: _classifyOfferingsError(e),
        debugMessage: e.toString(),
      );
    }
  }

  List<Package> _packagesFrom(Offerings offerings) {
    final seen = <String>{};
    final out = <Package>[];

    void addAll(Iterable<Package> packages) {
      for (final package in packages) {
        final id = package.storeProduct.identifier;
        if (seen.add(id)) out.add(package);
      }
    }

    final current = offerings.current;
    if (current != null) addAll(current.availablePackages);
    for (final offering in offerings.all.values) {
      addAll(offering.availablePackages);
    }
    return out;
  }

  /// When the "current" offering is empty but products exist in the store
  /// (StoreKit config / Play), still surface them for purchase.
  Future<List<Package>> _packagesFromProductIds() async {
    try {
      final products = await Purchases.getProducts(
        AppConstants.subscriptionProductIds,
        productCategory: ProductCategory.subscription,
      );
      return [
        for (final product in products)
          Package(
            product.identifier,
            _packageTypeFor(product.identifier),
            product,
            const PresentedOfferingContext('fallback', null, null),
          ),
      ];
    } catch (e) {
      debugPrint('getProducts fallback error: $e');
      return const [];
    }
  }

  PackageType _packageTypeFor(String productId) {
    if (productId.contains('weekly')) return PackageType.weekly;
    if (productId.contains('yearly') || productId.contains('annual')) {
      return PackageType.annual;
    }
    if (productId.contains('monthly')) return PackageType.monthly;
    return PackageType.custom;
  }

  OfferingsFailure _classifyOfferingsError(Object error) {
    final text = error.toString().toLowerCase();
    if (error is PlatformException) {
      if (error.code == '23' ||
          text.contains('test store') ||
          text.contains('configuration')) {
        return _isTestKey
            ? OfferingsFailure.testStoreEmpty
            : OfferingsFailure.empty;
      }
    }
    if (text.contains('billing') ||
        text.contains('storekit') ||
        text.contains('purchasenotallowed') ||
        text.contains('not allowed to make the purchase')) {
      return OfferingsFailure.storeUnavailable;
    }
    if (text.contains('network') ||
        text.contains('offline') ||
        text.contains('internet')) {
      return OfferingsFailure.unknown;
    }
    return _isTestKey
        ? OfferingsFailure.testStoreEmpty
        : OfferingsFailure.unknown;
  }

  Future<SubscriptionStatus> purchase(Package package) async {
    if (!_initialized) return SubscriptionStatus.free();
    try {
      final PurchaseResult result =
          package.presentedOfferingContext.offeringIdentifier == 'fallback'
              ? await Purchases.purchaseStoreProduct(package.storeProduct)
              : await Purchases.purchasePackage(package);
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
