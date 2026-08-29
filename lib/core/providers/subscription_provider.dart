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
    String gateway = '',
    String? couponCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.checkout,
        data: {
          'plan_id': planId,
          // Omitted when empty so the server uses the admin's Active Gateway.
          if (gateway.isNotEmpty) 'gateway': gateway,
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

  /// Set when the last verifyPayment() failed, so the UI can say WHY.
  String? lastVerifyError;

  Future<bool> verifyPayment({
    required String orderId,
    required String gateway,
    String? paymentId,
    String? signature,
  }) async {
    lastVerifyError = null;
    try {
      await ApiClient.instance.post(
        ApiEndpoints.verifyPayment,
        data: {
          'order_id': orderId,
          if (gateway.isNotEmpty) 'gateway': gateway,
          'payment_id': ?paymentId,
          'signature': ?signature,
        },
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      // Swallowing this told a paying user nothing at all.
      lastVerifyError = apiErrorMessage(e);
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
      final data = Map<String, dynamic>.from(res.data as Map);
      // The API returns paise only; the checkout screen was reading a
      // `discount_in_rupees` key that has never existed, and rendered "₹null".
      final paise = (data['discount_in_paise'] as num?)?.toDouble() ?? 0;
      data['discount_in_rupees'] = (paise / 100).toStringAsFixed(2);
      state = CouponState(result: data);
    } catch (e) {
      // e.toString() printed the whole DioException — "…because the response
      // has a status code of 422…" — instead of the backend's own message.
      state = CouponState(error: apiErrorMessage(e));
    }
  }

  void reset() => state = const CouponState();
}

final couponProvider = StateNotifierProvider<CouponNotifier, CouponState>(
  (_) => CouponNotifier(),
);
