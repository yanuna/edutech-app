import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/branding_provider.dart';
import '../../../core/services/startup_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _startupDone = false;
  bool _authResolved = false;

  @override
  void initState() {
    super.initState();
    _runStartup();
  }

  Future<void> _runStartup() async {
    await ref.read(startupServiceProvider).fetch();
    if (mounted) setState(() => _startupDone = true);
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (!_startupDone || !_authResolved) return;
    final status = ref.read(authProvider).status;
    switch (status) {
      case AuthStatus.authenticated:
        context.go('/home');
      case AuthStatus.unverified:
        context.go('/verify-email');
      case AuthStatus.mobileUnverified:
        context.go('/verify-mobile');
      case AuthStatus.unauthenticated:
        context.go('/onboarding');
      case AuthStatus.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve auth from the CURRENT value, not just future changes. On a warm
    // cold-start the /profile call can finish before this widget first builds,
    // so a change-only listener would miss the loading→resolved transition and
    // the splash would hang forever. Watching catches the already-resolved case
    // on first build and any later change on rebuild.
    final authStatus = ref.watch(authProvider).status;
    if (authStatus != AuthStatus.loading && !_authResolved) {
      _authResolved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeNavigate();
      });
    }

    final branding = ref.watch(brandingProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [branding.primaryColor, branding.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                branding.appName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                branding.tagline,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
