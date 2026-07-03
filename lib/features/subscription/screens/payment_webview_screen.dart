import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

/// WebView-based payment screen for redirect-based gateways:
/// Paytm, PayU, Atom (NTT Data).
///
/// When the gateway redirects back to our webhook URL, we intercept the URL
/// and call /subscriptions/verify on our backend to confirm and fulfil.
class PaymentWebViewScreen extends StatefulWidget {
  final String orderId;
  final String payPageUrl;
  final String gatewayName;

  const PaymentWebViewScreen({
    super.key,
    required this.orderId,
    required this.payPageUrl,
    required this.gatewayName,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _verifying = false;

  // The webhook callback URLs we redirect to after payment
  static const _webhookPaths = [
    '/api/subscriptions/webhook/paytm',
    '/api/subscriptions/webhook/payu',
    '/api/subscriptions/webhook/atom',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) => _intercept(req),
        ),
      )
      ..loadRequest(Uri.parse(widget.payPageUrl));
  }

  NavigationDecision _intercept(NavigationRequest req) {
    final url = req.url;

    // If the gateway is redirecting to our callback URL, intercept and verify
    final isCallback = _webhookPaths.any((path) => url.contains(path));
    if (isCallback && !_verifying) {
      _verifyPayment();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _verifyPayment() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    try {
      await ApiClient.instance.dio.post(
        ApiEndpoints.subscriptionVerify,
        data: {'order_id': widget.orderId},
      );
      if (mounted) context.go('/profile/payment-success');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment verification failed. Contact support if amount was deducted.',
            ),
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay via ${_prettyName(widget.gatewayName)}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                  'Are you sure you want to cancel this payment?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    child: const Text('Yes, cancel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading || _verifying)
            Container(
              color: Colors.white70,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _verifying ? 'Verifying payment…' : 'Loading…',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _prettyName(String gateway) {
    return switch (gateway) {
      'paytm' => 'Paytm',
      'payu' => 'PayU',
      'atom' => 'Atom / NTT Data',
      _ => gateway,
    };
  }
}
