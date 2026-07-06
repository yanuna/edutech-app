import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../providers/branding_provider.dart';
import 'ad_service.dart';

/// Public payment config surfaced from /startup — razorpay publishable key, active gateway.
final paymentConfigProvider = StateProvider<Map<String, String>>(
  (ref) => const {},
);

/// Admin-configurable exam countdown shown on the home screen. Defaults match
/// the backend defaults so the card renders before the first /startup returns.
class ExamCountdown {
  final bool enabled;
  final String label;
  final DateTime? date;
  const ExamCountdown({this.enabled = false, this.label = '', this.date});

  static final fallback = ExamCountdown(enabled: true, label: 'UPSC Prelims 2027', date: DateTime(2027, 5, 23));

  factory ExamCountdown.fromJson(Map<String, dynamic> json) {
    return ExamCountdown(
      enabled: json['enabled'] == true,
      label: json['label']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
    );
  }
}

final examCountdownProvider = StateProvider<ExamCountdown>((ref) => ExamCountdown.fallback);

/// Which social-login buttons to show, controlled from the admin panel.
class SocialLoginConfig {
  final bool googleEnabled;
  final bool facebookEnabled;
  const SocialLoginConfig({
    this.googleEnabled = true,
    this.facebookEnabled = false,
  });
}

final socialLoginProvider = StateProvider<SocialLoginConfig>(
  (ref) => const SocialLoginConfig(),
);

/// Globally-enabled product modules (admin-controlled via /startup).
/// Defaults to all-on so the app works before the first startup call returns.
final enabledModulesProvider = StateProvider<Set<String>>(
  (ref) => const {
    'study_material',
    'exam',
    'test_series',
    'news',
    'govt_jobs',
    'gamification',
  },
);

class StartupResult {
  final bool maintenanceMode;
  final bool forceUpdate;
  final int latestVersionCode;
  final int minRequiredVersionCode;
  final String? quote;

  const StartupResult({
    required this.maintenanceMode,
    required this.forceUpdate,
    required this.latestVersionCode,
    required this.minRequiredVersionCode,
    this.quote,
  });

  static const StartupResult defaults = StartupResult(
    maintenanceMode: false,
    forceUpdate: false,
    latestVersionCode: 1,
    minRequiredVersionCode: 1,
  );
}

class StartupService {
  StartupService(this._ref);
  final Ref _ref;

  /// Calls /startup, applies branding + ads config, returns version/maintenance info.
  /// Never throws — returns defaults on any error so the app always starts.
  Future<StartupResult> fetch() async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final res = await ApiClient.instance.dio.get(
        ApiEndpoints.startup,
        options: Options(headers: {'X-Platform': platform}),
      );
      final data = res.data as Map<String, dynamic>;

      // Apply branding colours + app name
      final brandingJson = data['branding'] as Map<String, dynamic>?;
      if (brandingJson != null) {
        _ref.read(brandingProvider.notifier).apply(brandingJson);
      }

      // Apply ad config (unit IDs, enabled flag, provider)
      final adsJson = data['ads'] as Map<String, dynamic>?;
      if (adsJson != null) {
        AdService.instance.applyConfig(AdConfig.fromJson(adsJson));
      }

      // Home screen exam countdown (admin-configurable)
      final homeJson = data['home'] as Map<String, dynamic>?;
      final countdownJson = homeJson?['exam_countdown'] as Map<String, dynamic>?;
      if (countdownJson != null) {
        _ref.read(examCountdownProvider.notifier).state = ExamCountdown.fromJson(countdownJson);
      }

      // Store payment config (razorpay publishable key, active gateway)
      final paymentJson = data['payment'] as Map<String, dynamic>?;
      if (paymentJson != null) {
        _ref.read(paymentConfigProvider.notifier).state = paymentJson.map(
          (k, v) => MapEntry(k, v?.toString() ?? ''),
        );
      }

      // Which social-login buttons to show (admin-controlled)
      final socialJson = data['social_login'] as Map<String, dynamic>?;
      if (socialJson != null) {
        _ref.read(socialLoginProvider.notifier).state = SocialLoginConfig(
          googleEnabled: socialJson['google_enabled'] as bool? ?? false,
          facebookEnabled: socialJson['facebook_enabled'] as bool? ?? false,
        );
      }

      // Which product modules are enabled (admin-controlled)
      final modulesJson = data['modules'] as List?;
      if (modulesJson != null) {
        _ref.read(enabledModulesProvider.notifier).state = modulesJson
            .whereType<Map>()
            .where((m) => m['enabled'] == true)
            .map((m) => m['key'].toString())
            .toSet();
      }

      return StartupResult(
        maintenanceMode: (data['maintenance_mode'] as bool?) ?? false,
        forceUpdate: (data['force_update'] as bool?) ?? false,
        latestVersionCode: (data['latest_version_code'] as int?) ?? 1,
        minRequiredVersionCode:
            (data['min_required_version_code'] as int?) ?? 1,
        quote: data['quote'] as String?,
      );
    } catch (_) {
      return StartupResult.defaults;
    }
  }
}

final startupServiceProvider = Provider<StartupService>(
  (ref) => StartupService(ref),
);
