import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../utils/storage.dart';

enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
  unverified,
  mobileUnverified,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  Future<void> _init() async {
    final token = await AppStorage.instance.getToken();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.profile);
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      final emailReq = await AppStorage.instance.emailVerifyRequired();
      final mobileReq = await AppStorage.instance.mobileVerifyRequired();
      state = AuthState(
        status: _statusFor(user, emailReq, mobileReq),
        user: user,
      );
    } catch (_) {
      await AppStorage.instance.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Decides the post-auth routing status from the user + which verifications
  /// the backend currently requires.
  AuthStatus _statusFor(User user, bool emailRequired, bool mobileRequired) {
    if (mobileRequired && user.mobileNumber != null && !user.isMobileVerified) {
      return AuthStatus.mobileUnverified;
    }
    if (emailRequired && !user.isEmailVerified) {
      return AuthStatus.unverified;
    }
    return AuthStatus.authenticated;
  }

  /// Persists the requirement flags from an auth response and builds the state.
  Future<AuthState> _applyAuth(User user, Map data) async {
    final emailReq = data['email_verification_required'] as bool? ?? true;
    final mobileReq = data['mobile_verification_required'] as bool? ?? false;
    await AppStorage.instance.saveVerifyFlags(
      email: emailReq,
      mobile: mobileReq,
    );
    return AuthState(status: _statusFor(user, emailReq, mobileReq), user: user);
  }

  // ── FCM token upload ──────────────────────────────────────────────────────

  /// Fetches the current FCM token and POSTs it to the backend via updateProfile.
  /// Called after every login / token refresh. Fails silently — FCM is optional.
  Future<void> _uploadFcmToken() async {
    try {
      final fcmToken = await NotificationService.instance.getToken();
      if (fcmToken == null) return;
      await ApiClient.instance.post(
        ApiEndpoints.updateProfile,
        data: {'fcm_token': fcmToken},
      );
    } catch (_) {}
  }

  Future<void> register({
    required String name,
    required String email,
    required String mobileNumber,
    required String password,
    String? referralCode,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'mobile_number': mobileNumber,
          'password': password,
          'password_confirmation': password,
          'referral_code': ?referralCode,
        },
      );
      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      await AppStorage.instance.saveToken(token);
      state = await _applyAuth(user, res.data as Map);
      _uploadFcmToken();
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: apiErrorMessage(e),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      await AppStorage.instance.saveToken(token);
      state = await _applyAuth(user, res.data as Map);
      _uploadFcmToken();
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: apiErrorMessage(e),
      );
    }
  }

  Future<void> googleLogin(String accessToken) =>
      _socialLogin('google', accessToken);

  Future<void> facebookLogin(String accessToken) =>
      _socialLogin('facebook', accessToken);

  /// Verifies a provider access token with the backend (/social-login) and
  /// logs the user in. The backend marks social accounts email-verified.
  Future<void> _socialLogin(String provider, String accessToken) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.socialLogin,
        data: {'provider': provider, 'access_token': accessToken},
      );
      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      await AppStorage.instance.saveToken(token);
      state = await _applyAuth(user, res.data as Map);
      _uploadFcmToken();
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: apiErrorMessage(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post(ApiEndpoints.logout);
    } catch (_) {}
    await AppStorage.instance.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called by the API client when a request 401s (token revoked/expired).
  /// Storage is already cleared there; just reset auth state so the router
  /// sends the user back to /login.
  void handleUnauthorized() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called when Firebase rotates the FCM token — silently re-uploads to backend.
  Future<void> updateFcmToken(String token) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.updateProfile,
        data: {'fcm_token': token},
      );
    } catch (_) {}
  }

  Future<void> resendVerificationEmail() async {
    await ApiClient.instance.post(ApiEndpoints.resendVerification);
  }

  /// Sends an OTP to the user's mobile. Returns null on success, or an error
  /// message (e.g. cooldown / daily-limit) to show the user.
  Future<String?> sendOtp() async {
    try {
      await ApiClient.instance.post(ApiEndpoints.otpSend);
      return null;
    } catch (e) {
      return apiErrorMessage(e);
    }
  }

  /// Verifies the entered OTP. On success refreshes the user and recomputes the
  /// routing status (so the router moves the user onward).
  Future<bool> verifyOtp(String code) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.otpVerify,
        data: {'code': code},
      );
      final res = await ApiClient.instance.get(ApiEndpoints.profile);
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      final emailReq = await AppStorage.instance.emailVerifyRequired();
      final mobileReq = await AppStorage.instance.mobileVerifyRequired();
      state = AuthState(
        status: _statusFor(user, emailReq, mobileReq),
        user: user,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.profile);
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<bool> updateProfile({String? name, String? mobileNumber}) async {
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.updateProfile,
        data: {'name': ?name, 'mobile_number': ?mobileNumber},
      );
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
