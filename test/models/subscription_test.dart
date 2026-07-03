import 'package:edutech_app/core/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionStatus', () {
    test('parses a subscribed status with active subscription', () {
      final s = SubscriptionStatus.fromJson({
        'is_subscribed': true,
        'show_ads': false,
        'has_access': true,
        'subscription': {
          'plan_id': 2,
          'plan_name': 'Premium',
          'start_date': '2026-01-01',
          'end_date': '2026-12-31',
          'status': 'active',
          'is_ad_supported': false,
          'source': 'purchase',
        },
      });
      expect(s.isSubscribed, isTrue);
      expect(s.showAds, isFalse);
      expect(s.hasAccess, isTrue);
      expect(s.subscription, isNotNull);
      expect(s.subscription!.planName, 'Premium');
      expect(s.subscription!.isAdSupported, isFalse);
    });

    test('defaults a free user to show ads with no subscription', () {
      final s = SubscriptionStatus.fromJson(const {});
      expect(s.isSubscribed, isFalse);
      expect(s.showAds, isTrue);
      expect(s.hasAccess, isFalse);
      expect(s.subscription, isNull);
    });
  });

  group('SubscriptionPlan', () {
    test('parses plan pricing fields', () {
      final p = SubscriptionPlan.fromJson({
        'id': 1,
        'name': 'Yearly',
        'price_in_paise': 99900,
        'price_in_rupees': '999',
        'validity_days': 365,
        'features': ['Ads free', 'Unlimited exams'],
      });
      expect(p.id, 1);
      expect(p.priceInPaise, 99900);
      expect(p.priceInRupees, '999');
      expect(p.validityDays, 365);
      expect(p.features, contains('Ads free'));
    });
  });

  group('CheckoutResponse', () {
    test('parses gateway order details', () {
      final c = CheckoutResponse.fromJson({
        'order_id': 'ord_1',
        'gateway_order_id': 'gw_1',
        'gateway_name': 'razorpay',
        'amount_in_paise': 99900,
        'amount_in_rupees': '999',
      });
      expect(c.orderId, 'ord_1');
      expect(c.gatewayName, 'razorpay');
      expect(c.payPageUrl, isNull);
    });
  });
}
