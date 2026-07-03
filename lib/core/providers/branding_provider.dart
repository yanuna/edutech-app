import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrandingConfig {
  final String appName;
  final String tagline;
  final Color primaryColor;
  final Color secondaryColor;
  final String supportEmail;
  final String supportWhatsapp;
  final String privacyUrl;
  final String termsUrl;

  const BrandingConfig({
    required this.appName,
    required this.tagline,
    required this.primaryColor,
    required this.secondaryColor,
    required this.supportEmail,
    required this.supportWhatsapp,
    required this.privacyUrl,
    required this.termsUrl,
  });

  static const BrandingConfig defaults = BrandingConfig(
    appName: 'EduTech',
    tagline: 'Learn · Practice · Excel',
    primaryColor: Color(0xFF4F46E5),
    secondaryColor: Color(0xFF7C3AED),
    supportEmail: '',
    supportWhatsapp: '',
    privacyUrl: '',
    termsUrl: '',
  );

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    Color parseHex(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      final clean = hex.replaceAll('#', '');
      final value = int.tryParse(
        clean.length == 6 ? 'FF$clean' : clean,
        radix: 16,
      );
      return value != null ? Color(value) : fallback;
    }

    return BrandingConfig(
      appName: json['app_name'] as String? ?? defaults.appName,
      tagline: json['tagline'] as String? ?? defaults.tagline,
      primaryColor: parseHex(
        json['primary_color'] as String?,
        defaults.primaryColor,
      ),
      secondaryColor: parseHex(
        json['secondary_color'] as String?,
        defaults.secondaryColor,
      ),
      supportEmail: json['support_email'] as String? ?? '',
      supportWhatsapp: json['support_whatsapp'] as String? ?? '',
      privacyUrl: json['privacy_url'] as String? ?? '',
      termsUrl: json['terms_url'] as String? ?? '',
    );
  }

  // Used for startup quote + version info stored alongside branding
  bool get hasSupport => supportEmail.isNotEmpty || supportWhatsapp.isNotEmpty;
}

class BrandingNotifier extends StateNotifier<BrandingConfig> {
  BrandingNotifier() : super(BrandingConfig.defaults);

  /// Called once during app startup with the branding block from /startup response.
  void apply(Map<String, dynamic> brandingJson) {
    state = BrandingConfig.fromJson(brandingJson);
  }
}

final brandingProvider =
    StateNotifierProvider<BrandingNotifier, BrandingConfig>(
      (_) => BrandingNotifier(),
    );
