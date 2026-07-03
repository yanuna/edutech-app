import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Holds the ad configuration fetched from /startup (via /api/ads-config).
/// Ad unit IDs are managed in the Filament admin panel under Settings → Ads.
class AdConfig {
  final bool enabled;
  final String provider; // 'admob' | 'facebook' | 'both'

  // AdMob unit IDs
  final String admobBannerId;
  final String admobInterstitialId;
  final String admobRewardedId;
  final String admobRewardedInterstitialId;
  final String admobNativeId;
  final String admobAppOpenId;

  // Facebook Audience Network placement IDs
  final String fbBannerId;
  final String fbInterstitialId;
  final String fbRewardedId;
  final String fbNativeId;

  const AdConfig({
    this.enabled = true,
    this.provider = 'admob',
    this.admobBannerId = '',
    this.admobInterstitialId = '',
    this.admobRewardedId = '',
    this.admobRewardedInterstitialId = '',
    this.admobNativeId = '',
    this.admobAppOpenId = '',
    this.fbBannerId = '',
    this.fbInterstitialId = '',
    this.fbRewardedId = '',
    this.fbNativeId = '',
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    return AdConfig(
      enabled: (json['enabled'] as bool?) ?? true,
      provider: (json['provider'] as String?) ?? 'admob',
      admobBannerId: (json['admob_banner_id'] as String?) ?? '',
      admobInterstitialId: (json['admob_interstitial_id'] as String?) ?? '',
      admobRewardedId: (json['admob_rewarded_id'] as String?) ?? '',
      admobRewardedInterstitialId:
          (json['admob_rewarded_interstitial_id'] as String?) ?? '',
      admobNativeId: (json['admob_native_id'] as String?) ?? '',
      admobAppOpenId: (json['admob_app_open_id'] as String?) ?? '',
      fbBannerId: (json['facebook_banner_id'] as String?) ?? '',
      fbInterstitialId: (json['facebook_interstitial_id'] as String?) ?? '',
      fbRewardedId: (json['facebook_rewarded_id'] as String?) ?? '',
      fbNativeId: (json['facebook_native_id'] as String?) ?? '',
    );
  }

  // Test IDs for development — Google's official test unit IDs
  static AdConfig get testConfig => const AdConfig(
    enabled: true,
    provider: 'admob',
    admobBannerId: 'ca-app-pub-3940256099942544/6300978111',
    admobInterstitialId: 'ca-app-pub-3940256099942544/1033173712',
    admobRewardedId: 'ca-app-pub-3940256099942544/5224354917',
    admobRewardedInterstitialId: 'ca-app-pub-3940256099942544/5354046379',
    admobNativeId: 'ca-app-pub-3940256099942544/2247696110',
    admobAppOpenId: 'ca-app-pub-3940256099942544/9257395921',
    fbBannerId: 'IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID',
    fbInterstitialId: 'YOUR_INTERSTITIAL_PLACEMENT_ID',
    fbRewardedId: 'YOUR_REWARDED_PLACEMENT_ID',
    fbNativeId: 'YOUR_NATIVE_PLACEMENT_ID',
  );
}

/// Singleton that owns all loaded ad instances.
/// Call [AdService.instance.initialize()] once in main().
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  AdConfig _config = kDebugMode ? AdConfig.testConfig : const AdConfig();
  bool _initialized = false;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpen;

  bool get enabled => _config.enabled;
  bool get usesAdMob =>
      _config.provider == 'admob' || _config.provider == 'both';
  bool get usesFacebook =>
      _config.provider == 'facebook' || _config.provider == 'both';

  /// Called once in main() after Firebase is initialized.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!enabled) return;

    await MobileAds.instance.initialize();
    _preloadInterstitial();
    _preloadRewarded();
  }

  /// Called from startupService after branding is applied.
  void applyConfig(AdConfig config) {
    _config = config;
    if (!_initialized) return;
    _preloadInterstitial();
    _preloadRewarded();
  }

  // ── Banner (created per-widget, not pre-loaded) ───────────────────────────

  BannerAd? createBanner({
    AdSize size = AdSize.banner,
    BannerAdListener? listener,
  }) {
    if (!enabled || !usesAdMob || _config.admobBannerId.isEmpty) return null;
    return BannerAd(
      adUnitId: _config.admobBannerId,
      size: size,
      request: const AdRequest(),
      // `BannerAd.listener` is final, so it must be supplied here at construction.
      listener: listener ?? BannerAdListener(),
    );
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  void _preloadInterstitial() {
    if (!enabled || !usesAdMob || _config.admobInterstitialId.isEmpty) return;
    _interstitial?.dispose();
    _interstitial = null;

    InterstitialAd.load(
      adUnitId: _config.admobInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
        },
      ),
    );
  }

  /// Show interstitial if loaded, then immediately reload for next time.
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return false;

    _interstitial = null; // Consume before showing
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _preloadInterstitial();
      },
    );
    ad.show();
    return true;
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  void _preloadRewarded() {
    if (!enabled || !usesAdMob || _config.admobRewardedId.isEmpty) return;
    _rewarded?.dispose();
    _rewarded = null;

    RewardedAd.load(
      adUnitId: _config.admobRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
        },
      ),
    );
  }

  /// Show rewarded ad. [onRewarded] is called with (type, amount) when user earns reward.
  Future<bool> showRewarded({
    required void Function(String, double) onRewarded,
  }) async {
    final ad = _rewarded;
    if (ad == null) return false;

    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _preloadRewarded();
      },
    );
    ad.show(
      onUserEarnedReward: (_, reward) =>
          onRewarded(reward.type, reward.amount.toDouble()),
    );
    return true;
  }

  // ── App Open ──────────────────────────────────────────────────────────────

  void preloadAppOpen() {
    if (!enabled || !usesAdMob || _config.admobAppOpenId.isEmpty) return;

    AppOpenAd.load(
      adUnitId: _config.admobAppOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
        },
        onAdFailedToLoad: (_) {
          _appOpen = null;
        },
      ),
    );
  }

  Future<bool> showAppOpen() async {
    final ad = _appOpen;
    if (ad == null) return false;

    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        preloadAppOpen();
      },
    );
    ad.show();
    return true;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _appOpen?.dispose();
  }
}
