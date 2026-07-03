import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/startup_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final int planId;
  final String gateway;
  const CheckoutScreen({
    super.key,
    required this.planId,
    required this.gateway,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponCtrl = TextEditingController();
  Razorpay? _razorpay;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    if (_couponCtrl.text.trim().isEmpty) return;
    await ref
        .read(couponProvider.notifier)
        .apply(code: _couponCtrl.text.trim(), planId: widget.planId);
    setState(() {});
  }

  Future<void> _initiatePayment() async {
    final coupon = ref.read(couponProvider).result != null
        ? _couponCtrl.text.trim()
        : null;

    final checkout = await ref
        .read(checkoutProvider.notifier)
        .initiateCheckout(
          planId: widget.planId,
          gateway: widget.gateway,
          couponCode: coupon,
        );

    if (checkout == null || !mounted) return;
    _pendingOrderId = checkout.orderId;

    if (widget.gateway == 'razorpay') {
      final user = ref.read(authProvider).user;
      final rzpKey = ref.read(paymentConfigProvider)['razorpay_key_id'] ?? '';
      final options = {
        'key': rzpKey,
        'amount': checkout.amountInPaise,
        'order_id': checkout.gatewayOrderId,
        'name': 'EduTech',
        'description': 'Subscription',
        'prefill': {
          'contact': '',
          'email': user?.email ?? '',
          'name': user?.name ?? '',
        },
        'theme': {'color': '#4F46E5'},
      };
      _razorpay!.open(options);
    } else if (checkout.payPageUrl != null && checkout.payPageUrl!.isNotEmpty) {
      // Paytm / PayU / Atom — open redirect URL in WebView
      if (!mounted) return;
      context.push(
        '/profile/payment-webview'
        '?order_id=${Uri.encodeComponent(_pendingOrderId!)}'
        '&pay_page_url=${Uri.encodeComponent(checkout.payPageUrl!)}'
        '&gateway=${Uri.encodeComponent(widget.gateway)}',
      );
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    if (_pendingOrderId == null) return;
    final ok = await ref
        .read(checkoutProvider.notifier)
        .verifyPayment(
          orderId: _pendingOrderId!,
          gateway: 'razorpay',
          paymentId: response.paymentId,
          signature: response.signature,
        );
    if (mounted) {
      if (ok) {
        ref.invalidate(subscriptionStatusProvider);
        context.pushReplacement('/profile/payment-success');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed.')),
        );
      }
    }
  }

  void _onError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message}')),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  String _gatewayLabel(String gateway) {
    switch (gateway) {
      case 'razorpay':
        return 'Razorpay';
      case 'paytm':
        return 'Paytm';
      case 'payu':
        return 'PayU';
      case 'atom':
        return 'Atom (NTT Data)';
      default:
        return gateway.isEmpty
            ? 'Payment'
            : gateway[0].toUpperCase() + gateway.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final couponState = ref.watch(couponProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coupon section
            const Text(
              'Have a coupon?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter coupon code',
                      prefixIcon: Icon(Icons.discount_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: couponState.isLoading ? null : _applyCoupon,
                  // The global theme makes FilledButtons full-width
                  // (minimumSize width = infinity); inside this Row that forces
                  // an infinite width, so give this one a bounded size.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 52),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
            if (couponState.isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (couponState.result != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      'Discount: ₹${couponState.result!['discount_in_rupees']}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (couponState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                couponState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 32),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  Text(
                    _gatewayLabel(widget.gateway),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.radio_button_checked,
                    color: Color(0xFF4F46E5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: checkoutState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  onPressed: _initiatePayment,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Pay Securely'),
                ),
        ),
      ),
    );
  }
}
