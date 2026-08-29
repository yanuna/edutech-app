import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollTimer;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    // Poll every 5 s to detect verification
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) {
        final status = ref.read(authProvider).status;
        if (status == AuthStatus.authenticated) {
          context.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _resending = true);

    // resendVerificationEmail() has no try/catch and rethrows. The route is
    // throttle:6,1, so one 429 (or a dropped connection) propagated out of here
    // and _resending was never reset — the button became a permanent spinner
    // and only an app restart got the user off this screen.
    String? error;
    try {
      await ref.read(authProvider.notifier).resendVerificationEmail();
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Verification email resent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authProvider).user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify your email',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open the email and click the link to activate your account. This screen auto-detects verification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 40),
              _resending
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _resend,
                        child: const Text('Resend Email'),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text(
                  'Use a different account',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
