import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/subscription.dart';

// ─── Plans (public) ────────────────────────────────────────────────────────

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((
  ref,
) async {
  final res = await ApiClient.instance.get(ApiEndpoints.subscriptionPlans);
  return (res.data['plans'] as List)
      .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Current status ────────────────────────────────────────────────────────

final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((
  ref,
) async {
  final res = await ApiClient.instance.get(ApiEndpoints.subscriptionStatus);
  return SubscriptionStatus.fromJson(res.data as Map<String, dynamic>);
});

// ─── Checkout flow ────────────────────────────────────────────────────────

class CheckoutNotifier extends StateNotifier<AsyncValue<CheckoutResponse?>> {
  CheckoutNotifier() : super(const AsyncValue.data(null));

  Future<CheckoutResponse?> initiateCheckout({
    required int planId,
    required String gateway,
    String? couponCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.checkout,
        data: {
          'plan_id': planId,
          'gateway': gateway,
          'coupon_code': ?couponCode,
        },
      );
      final checkout = CheckoutResponse.fromJson(
        res.data as Map<String, dynamic>,
      );
      state = AsyncValue.data(checkout);
      return checkout;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String gateway,
    String? paymentId,
    String? signature,
  }) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.verifyPayment,
        data: {
          'order_id': orderId,
          'gateway': gateway,
          'payment_id': ?paymentId,
          'signature': ?signature,
        },
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, AsyncValue<CheckoutResponse?>>(
      (_) => CheckoutNotifier(),
    );

// ─── Coupon preview ────────────────────────────────────────────────────────

class CouponState {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  const CouponState({this.isLoading = false, this.result, this.error});
}

class CouponNotifier extends StateNotifier<CouponState> {
  CouponNotifier() : super(const CouponState());

  Future<void> apply({required String code, required int planId}) async {
    state = const CouponState(isLoading: true);
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.applyCoupon,
        data: {'coupon_code': code, 'plan_id': planId},
      );
      state = CouponState(result: res.data as Map<String, dynamic>);
    } catch (e) {
      state = CouponState(error: e.toString());
    }
  }

  void reset() => state = const CouponState();
}

final couponProvider = StateNotifierProvider<CouponNotifier, CouponState>(
  (_) => CouponNotifier(),
);
