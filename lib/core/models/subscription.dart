class SubscriptionPlan {
  final int id;
  final String name;
  final String? description;
  final int priceInPaise;
  final String priceInRupees;
  final int validityDays;
  final List<String>? features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.priceInPaise,
    required this.priceInRupees,
    required this.validityDays,
    this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
    id: j['id'] as int,
    name: j['name'] as String,
    description: j['description'] as String?,
    priceInPaise: j['price_in_paise'] as int,
    priceInRupees: j['price_in_rupees'] as String,
    validityDays: j['validity_days'] as int,
    features: (j['features'] as List?)?.map((e) => e.toString()).toList(),
  );
}

class SubscriptionStatus {
  final bool isSubscribed;
  final bool showAds;
  final bool hasAccess;
  final ActiveSubscription? subscription;

  const SubscriptionStatus({
    required this.isSubscribed,
    required this.showAds,
    required this.hasAccess,
    this.subscription,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) {
    final sub = j['subscription'] as Map<String, dynamic>?;
    return SubscriptionStatus(
      isSubscribed: j['is_subscribed'] as bool? ?? false,
      showAds: j['show_ads'] as bool? ?? true,
      hasAccess: j['has_access'] as bool? ?? false,
      subscription: sub != null ? ActiveSubscription.fromJson(sub) : null,
    );
  }
}

class ActiveSubscription {
  final int? planId;
  final String? planName;
  final String startDate;
  final String endDate;
  final String status;
  final bool isAdSupported;
  final String source;

  const ActiveSubscription({
    this.planId,
    this.planName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isAdSupported,
    required this.source,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ActiveSubscription(
        planId: j['plan_id'] as int?,
        planName: j['plan_name'] as String?,
        startDate: j['start_date'] as String,
        endDate: j['end_date'] as String,
        status: j['status'] as String,
        isAdSupported: j['is_ad_supported'] as bool? ?? true,
        source: j['source'] as String? ?? 'purchase',
      );
}

class CheckoutResponse {
  final String orderId;
  final String gatewayOrderId;
  final String gatewayName;
  final int amountInPaise;
  final String amountInRupees;

  /// Hosted pay page for redirect gateways (Paytm / PayU / Atom / PhonePe).
  final String? payPageUrl;

  /// False when a coupon covered the whole price: the plan is already granted
  /// and the app must skip the payment sheet entirely. Every Indian gateway
  /// rejects a ₹0 order, so this used to die inside the gateway call.
  final bool requiresPayment;

  /// True when a discount was applied, for the confirmation UI.
  final bool discountApplied;

  const CheckoutResponse({
    required this.orderId,
    required this.gatewayOrderId,
    required this.gatewayName,
    required this.amountInPaise,
    required this.amountInRupees,
    this.payPageUrl,
    this.requiresPayment = true,
    this.discountApplied = false,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> j) => CheckoutResponse(
    // Defensive casts: a gateway error response reaching this parser used to
    // throw a raw type error instead of surfacing the server's message.
    orderId: (j['order_id'] ?? '').toString(),
    gatewayOrderId: (j['gateway_order_id'] ?? '').toString(),
    gatewayName: (j['gateway_name'] ?? '').toString(),
    amountInPaise: (j['amount_in_paise'] as num?)?.toInt() ?? 0,
    amountInRupees: (j['amount_in_rupees'] ?? '0.00').toString(),
    payPageUrl: j['pay_page_url'] as String?,
    requiresPayment: j['requires_payment'] as bool? ?? true,
    discountApplied: j['discount_applied'] as bool? ?? false,
  );
}
