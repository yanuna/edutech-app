import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

/// WebView payment screen for redirect-based gateways: Paytm, PayU, Atom.
///
/// Three things this screen has to get right, all of which it previously got
/// wrong and each of which meant "the student paid and got nothing":
///
///  1. The verify call MUST identify the order. It sent only `order_id` while
///     the server required `gateway` too, so every verification returned 422
///     and the app told the payer "verification failed" on a captured payment.
///     (The server now resolves the gateway from the order, and the app sends
///     it as well — either half alone fixes it; both is deliberate.)
///
///  2. Landing on a callback URL is NOT proof of success. PayU posts to the
///     same `furl` when a payment is DECLINED, so "URL contains a webhook path"
///     reported failures as successes. Only the server's own status poll decides.
///
///  3. The interception can simply not fire. Gateways return via a form POST,
///     and Android does not invoke onNavigationRequest for form-POST
///     navigations — the payer was left staring at raw JSON. The screen now
///     also polls the subscription status, so confirmation no longer depends on
///     catching a redirect.
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
  bool _finished = false;
  Timer? _poller;

  /// Paths the gateway returns to once the payer is done — either outcome.
  static const _returnPaths = [
    '/api/subscriptions/webhook/',
    '/checkout/return/',
    '/checkout/result',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _loading = true);
            _maybeConfirm(url);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            // Covers the Android form-POST case, where onNavigationRequest
            // never fires but the page still lands on our return URL.
            _maybeConfirm(url);
          },
          onNavigationRequest: (req) => _intercept(req),
        ),
      )
      ..loadRequest(Uri.parse(widget.payPageUrl));

    if (!_isAllowedHost(widget.payPageUrl)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That payment link is not recognised.')),
        );
        context.pop();
      });
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  bool _isOurReturnUrl(String url) =>
      _returnPaths.any((path) => url.contains(path));

  /// Hosts the payment flow is allowed to reach: the Indian gateways, the banks
  /// and UPI apps they hand off to, and our own domain.
  ///
  /// payPageUrl arrives as a query parameter and this route is reachable from a
  /// push-notification deep link, so without an allowlist a crafted
  /// notification could open ANY site inside a WebView with unrestricted
  /// JavaScript, wearing the app's "Pay via …" chrome.
  static const _allowedHostSuffixes = [
    'paytm.in', 'paytm.com', 'payu.in', 'payubiz.in', 'payumoney.com',
    'atomtech.in', 'phonepe.com', 'razorpay.com',
    'npci.org.in', 'upi.npci.org.in',
  ];

  bool _isAllowedHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return true; // about:blank, data:, …

    final appHost = Uri.tryParse(ApiEndpoints.baseUrl)?.host ?? '';
    final host = uri.host.toLowerCase();

    if (appHost.isNotEmpty && (host == appHost || host.endsWith('.$appHost'))) {
      return true;
    }

    // Banks redirect to a long tail of ACS/3-D Secure domains during a card
    // payment, so anything reached over plain HTTP is what actually matters.
    if (uri.scheme != 'https') return false;

    return _allowedHostSuffixes.any((s) => host == s || host.endsWith('.$s'));
  }

  NavigationDecision _intercept(NavigationRequest req) {
    if (_isOurReturnUrl(req.url)) {
      _maybeConfirm(req.url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _maybeConfirm(String url) {
    if (_finished || _verifying) return;
    if (!_isOurReturnUrl(url)) return;
    _confirmWithServer();
  }

  /// Ask our backend whether this order was really paid.
  ///
  /// The server re-checks with the gateway, so this is authoritative. A payment
  /// can take a few seconds to settle on the gateway side, so a "not completed
  /// yet" answer is retried rather than treated as a failure.
  Future<void> _confirmWithServer() async {
    if (_verifying || _finished) return;
    setState(() => _verifying = true);

    const attempts = 6;
    String? lastMessage;

    for (var i = 0; i < attempts; i++) {
      if (!mounted) return;

      try {
        final res = await ApiClient.instance.dio.post(
          ApiEndpoints.subscriptionVerify,
          data: {
            'order_id': widget.orderId,
            'gateway': widget.gatewayName,
          },
        );

        // 202 = another worker is fulfilling this same payment right now.
        if (res.statusCode == 202) {
          await Future<void>.delayed(const Duration(seconds: 3));
          continue;
        }

        if (!mounted) return;
        _finished = true;
        context.go('/profile/payment-success');
        return;
      } catch (e) {
        lastMessage = apiErrorMessage(e);

        // Still settling at the gateway — wait and ask again.
        await Future<void>.delayed(Duration(seconds: 2 + i));
      }
    }

    if (!mounted) return;
    setState(() => _verifying = false);

    // Everything below is "we could not confirm", not "you were not charged" —
    // the wording matters, because the money may well have left.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Payment not confirmed yet'),
        content: Text(
          "We couldn't confirm this payment with ${_prettyName(widget.gatewayName)} "
          'just now.\n\n'
          'If money was deducted, your subscription will activate automatically '
          'within a few minutes — no need to pay again.\n\n'
          'Order: ${widget.orderId}'
          '${lastMessage != null ? '\n\n($lastMessage)' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _confirmWithServer();
            },
            child: const Text('Check again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (mounted) context.pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              // They may have completed payment and backed out before the
              // redirect landed — check once before giving up on the order.
              _confirmWithServer();
            },
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pay via ${_prettyName(widget.gatewayName)}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmCancel,
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
                        _verifying
                            ? 'Confirming your payment…'
                            : 'Loading…',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_verifying) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Please don\'t close this screen.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _prettyName(String gateway) {
    return switch (gateway) {
      'paytm' => 'Paytm',
      'payu' => 'PayU',
      'atom' => 'Atom / NTT Data',
      'phonepe' => 'PhonePe',
      _ => gateway,
    };
  }
}
