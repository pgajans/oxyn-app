import 'package:purchases_flutter/purchases_flutter.dart';

enum OfferingsFailure {
  none,
  notReady,
  testStoreEmpty,
  storeUnavailable,
  empty,
  network,
  unknown,
}

class OfferingsLoadResult {
  final List<Package> packages;
  final OfferingsFailure failure;
  final String? debugMessage;

  const OfferingsLoadResult({
    required this.packages,
    this.failure = OfferingsFailure.none,
    this.debugMessage,
  });

  bool get hasPackages => packages.isNotEmpty;

  /// The device is online but the store offers nothing to buy (unsupported
  /// region, no billing account, store misconfiguration). Locking the user
  /// out in that case would leave the app unusable.
  bool get storeCannotSell =>
      !hasPackages && failure != OfferingsFailure.network;
}
