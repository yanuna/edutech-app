import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';

/// Drop-in banner ad widget. Shows nothing if ads are disabled or no unit ID configured.
///
/// Usage:
///   const AdBannerWidget()                          // default banner (320×50)
///   const AdBannerWidget(size: AdSize.largeBanner)  // 320×100
class AdBannerWidget extends StatefulWidget {
  final AdSize size;
  const AdBannerWidget({super.key, this.size = AdSize.banner});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // The listener is passed at construction because BannerAd.listener is final.
    final ad = AdService.instance.createBanner(
      size: widget.size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    );
    if (ad == null) return;

    _ad = ad..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
