import 'package:purchases_flutter/purchases_flutter.dart';

enum OfferingsFailure {
  none,
  notReady,
  testStoreEmpty,
  storeUnavailable,
  empty,
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
}
