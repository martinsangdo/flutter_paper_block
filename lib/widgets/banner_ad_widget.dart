import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_config.dart';

/// Bottom **Anchored Adaptive Banner**. Reserves a fixed slice of the layout
/// (full device width; height from Google's adaptive formula) so the gameplay
/// UI never shifts, then loads a real AdMob banner into it.
///
/// While the banner is loading (or if it fails / is unsupported) the reserved
/// box shows a neutral background of exactly the same height, so there is no
/// layout jump when the ad appears. Renders nothing on **web**.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  /// Fallback/reserved height used before the adaptive size is known. Matches
  /// Google's cap: 15% of screen height, clamped to the 50–90 dp banner band.
  static double reservedHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.15).clamp(50.0, 90.0);
  }

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _requested = false;

  // Retry-on-failure: a fresh banner is requested for every game screen, and
  // real/new AdMob units often return "No fill" on rapid repeat requests. Retry
  // a few times with backoff so later levels still get a banner.
  int _retries = 0;
  static const _maxRetries = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Adaptive banner size needs the screen width, so load here rather than in
    // initState. Guard so we only request once.
    if (!_requested) {
      _requested = true;
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (!AdConfig.adsSupported) return;

    final width = MediaQuery.of(context).size.width.truncate();
    // The app is portrait-locked (see main.dart), so request a portrait banner.
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          debugPrint('BannerAdWidget: load failed (attempt '
              '${_retries + 1}/${_maxRetries + 1}): $error');
          if (!mounted || _loaded || _retries >= _maxRetries) return;
          _retries++;
          // Backoff: 2s, 4s, 6s, 8s.
          Future.delayed(Duration(seconds: 2 * _retries), () {
            if (mounted && !_loaded) _loadBanner();
          });
        },
      ),
    );
    _bannerAd = banner;
    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !AdConfig.adsSupported) {
      return const SizedBox.shrink(); // ads disabled on web / desktop
    }

    // Height of the loaded banner if we have one, else the reserved height so
    // the layout is stable while the ad loads.
    final height = (_loaded && _bannerAd != null)
        ? _bannerAd!.size.height.toDouble()
        : BannerAdWidget.reservedHeight(context);

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: height,
        color: const Color(0xFFF0EAD8),
        alignment: Alignment.center,
        child: (_loaded && _bannerAd != null)
            ? AdWidget(ad: _bannerAd!)
            : const SizedBox.shrink(),
      ),
    );
  }
}
