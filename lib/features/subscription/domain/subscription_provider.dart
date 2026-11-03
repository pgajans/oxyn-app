import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/subscription_service.dart';
import 'access_gate.dart';
import 'offerings_load.dart';
import 'subscription_status.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionStatusNotifier, SubscriptionStatus>(
  SubscriptionStatusNotifier.new,
);

class SubscriptionStatusNotifier extends AsyncNotifier<SubscriptionStatus> {
  SubscriptionStatus? _lastKnown;

  @override
  Future<SubscriptionStatus> build() async {
    final service = ref.read(subscriptionServiceProvider);
    service.addStatusListener(_set);
    final status = await service.getSubscriptionStatus();
    _remember(status);
    return status;
  }

  void _remember(SubscriptionStatus status) {
    _lastKnown = status;
    accessGate.update(status.isPremium);
  }

  void _set(SubscriptionStatus status) {
    _remember(status);
    state = AsyncValue.data(status);
  }

  Future<SubscriptionStatus> purchase(Package package) async {
    try {
      final result =
          await ref.read(subscriptionServiceProvider).purchase(package);
      _set(result);
      return result;
    } catch (_) {
      final last = _lastKnown;
      if (last != null) state = AsyncValue.data(last);
      rethrow;
    }
  }

  /// Returns the restored status. On failure the last known status is kept,
  /// so a store hiccup never locks out an active subscriber.
  Future<SubscriptionStatus> restore() async {
    try {
      final result =
          await ref.read(subscriptionServiceProvider).restorePurchases();
      _set(result);
      return result;
    } catch (_) {
      final last = _lastKnown;
      if (last != null) state = AsyncValue.data(last);
      rethrow;
    }
  }

  Future<void> refresh() async {
    _set(await ref.read(subscriptionServiceProvider).getSubscriptionStatus());
  }
}

final offeringsProvider = FutureProvider<OfferingsLoadResult>((ref) async {
  return ref.read(subscriptionServiceProvider).getOfferings();
});

final _accessCodeProvider = Provider<bool>((ref) {
  void onChange() => ref.invalidateSelf();
  accessGate.addListener(onChange);
  ref.onDispose(() => accessGate.removeListener(onChange));
  return accessGate.hasAccessCode;
});

// Quick access to check if user is premium
final isPremiumProvider = Provider<bool>((ref) {
  if (ref.watch(_accessCodeProvider)) return true;
  return ref.watch(subscriptionStatusProvider).when(
        loading: () => accessGate.hasEntitlement,
        error: (e, s) => accessGate.hasEntitlement,
        data: (status) => status.isPremium,
      );
});
