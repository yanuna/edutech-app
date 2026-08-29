import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class VerifyMobileScreen extends ConsumerStatefulWidget {
  const VerifyMobileScreen({super.key});

  @override
  ConsumerState<VerifyMobileScreen> createState() => _VerifyMobileScreenState();
}

class _VerifyMobileScreenState extends ConsumerState<VerifyMobileScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  bool _sending = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Registration already sends a code (AuthController::register), and this
    // used to fire another one unconditionally — so simply opening the screen
    // burned a paid SMS and ate into the 5/min throttle, meaning a user who
    // came back to type the code they had just received could be rate-limited
    // out of verifying at all. Start the cooldown instead; "Resend" is one tap
    // away if the first message never arrived.
    _startCooldown();
  }

  @override
  void dispose() {
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 45);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _send({bool initial = false}) async {
    if (_sending || _cooldown > 0) return;
    setState(() => _sending = true);
    final err = await ref.read(authProvider.notifier).sendOtp();
    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _startCooldown();
      if (!initial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.')),
        );
      }
    } else if (!initial) {
      // Show real errors (cooldown/limit) only on a manual resend tap.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _verify() async {
    if (_code.text.trim().length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code.')));
      return;
    }
    setState(() => _verifying = true);
    final ok = await ref
        .read(authProvider.notifier)
        .verifyOtp(_code.text.trim());
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      // Router redirects on the new auth status; nudge to home as a fallback.
      final status = ref.read(authProvider).status;
      if (status == AuthStatus.authenticated) context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect or expired code. Please try again.'),
        ),
      );
    }
  }

  String get _masked {
    final m = ref.read(authProvider).user?.mobileNumber ?? '';
    if (m.length < 10) return m;
    return '${m.substring(0, 2)}••••${m.substring(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.smartphone,
                  size: 38,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify your mobile',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code we sent to $_masked',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 28),
              AppTextField(
                controller: _code,
                label: '6-digit OTP',
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 22),
              _verifying
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _verify,
                      child: const Text('Verify & continue'),
                    ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: (_cooldown > 0 || _sending) ? null : () => _send(),
                child: Text(
                  _cooldown > 0
                      ? 'Resend code in ${_cooldown}s'
                      : 'Resend code',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black45,
                    ),
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
