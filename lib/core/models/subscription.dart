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
  final String? payPageUrl; // PhonePe only

  const CheckoutResponse({
    required this.orderId,
    required this.gatewayOrderId,
    required this.gatewayName,
    required this.amountInPaise,
    required this.amountInRupees,
    this.payPageUrl,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> j) => CheckoutResponse(
    orderId: j['order_id'] as String,
    gatewayOrderId: j['gateway_order_id'] as String,
    gatewayName: j['gateway_name'] as String,
    amountInPaise: j['amount_in_paise'] as int,
    amountInRupees: j['amount_in_rupees'] as String,
    payPageUrl: j['pay_page_url'] as String?,
  );
}
