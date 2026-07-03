import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/startup_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _referral = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    _referral.dispose();
    super.dispose();
  }

  /// Cleans a mobile number (strips +91 / 0 / spaces, keeps last 10 digits).
  /// Returns the 10-digit number if it's a valid Indian mobile, else null.
  String? _cleanMobile(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length > 10) d = d.substring(d.length - 10);
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(d) ? d : null;
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await ref
        .read(authProvider.notifier)
        .register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          mobileNumber: _cleanMobile(_mobile.text)!,
          password: _password.text,
          referralCode: _referral.text.trim().isEmpty
              ? null
              : _referral.text.trim(),
        );
    if (mounted) {
      setState(() => _loading = false);
      final err = ref.read(authProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  // Social sign-up: the backend creates the account on first social login,
  // so the same flow doubles as registration.
  Future<void> _googleLogin() async {
    try {
      final gsi = GoogleSignIn(scopes: ['email', 'profile']);
      // Sign out first so Google always shows the account picker instead of
      // silently reusing the previously-signed-in account.
      await gsi.signOut();
      final account = await gsi.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      // Backend verifies via Socialite userFromToken(), which needs the OAuth
      // access token (not the id token).
      final token = auth.accessToken;
      if (token == null) return;
      if (mounted) {
        await ref.read(authProvider.notifier).googleLogin(token);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _facebookLogin() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success || result.accessToken == null) {
        return;
      }
      final token = result.accessToken!.tokenString;
      if (mounted) {
        await ref.read(authProvider.notifier).facebookLogin(token);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialLoginProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start your learning journey today',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _name,
                  label: 'Full Name',
                  prefix: const Icon(Icons.person_outline),
                  validator: (v) =>
                      v != null && v.length >= 2 ? null : 'Enter your name',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.email_outlined),
                  validator: (v) => v != null && v.contains('@')
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _mobile,
                  label: 'Mobile Number',
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone_outlined),
                  validator: (v) => _cleanMobile(v ?? '') != null
                      ? null
                      : 'Enter a valid 10-digit mobile number',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: _obscure,
                  prefix: const Icon(Icons.lock_outline),
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      v != null && v.length >= 8 ? null : 'Min 8 characters',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _referral,
                  label: 'Referral Code (optional)',
                  prefix: const Icon(Icons.card_giftcard_outlined),
                ),
                const SizedBox(height: 28),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _register,
                          child: const Text('Create Account'),
                        ),
                      ),
                const SizedBox(height: 16),
                const Text(
                  'By signing up you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                if (social.googleEnabled || social.facebookEnabled) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (social.googleEnabled)
                  OutlinedButton.icon(
                    onPressed: _googleLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 28,
                      color: Color(0xFFEA4335),
                    ),
                    label: const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (social.facebookEnabled) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _facebookLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(
                      Icons.facebook,
                      size: 24,
                      color: Color(0xFF1877F2),
                    ),
                    label: const Text(
                      'Sign up with Facebook',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
