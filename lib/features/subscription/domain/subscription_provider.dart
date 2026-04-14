import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/subscription_service.dart';
import 'subscription_status.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionStatusNotifier, SubscriptionStatus>(
  SubscriptionStatusNotifier.new,
);

class SubscriptionStatusNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    return ref.read(subscriptionServiceProvider).getSubscriptionStatus();
  }

  Future<void> purchase(Package package) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(subscriptionServiceProvider).purchase(package);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionServiceProvider).restorePurchases(),
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(subscriptionServiceProvider).getSubscriptionStatus(),
    );
  }
}

final offeringsProvider = FutureProvider<List<Package>>((ref) async {
  return ref.read(subscriptionServiceProvider).getOfferings();
});

// Quick access to check if user is premium
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionStatusProvider).when(
        loading: () => false,
        error: (e, s) => false,
        data: (status) => status.isPremium,
      );
});
