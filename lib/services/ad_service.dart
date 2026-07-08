import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Owns the Google Mobile Ads SDK lifecycle and the app's **rewarded ad** (used
/// to unlock a gameplay hint). Banner ads are self-contained in
/// `BannerAdWidget`; this service only handles SDK init + rewarded ads because
/// a rewarded ad is a one-shot, app-global object that must be preloaded.
///
/// A `ChangeNotifier` singleton so UI can react to load state (mirrors the
/// pattern used by `SoundService`). No-op on web / non-mobile platforms.
class AdService extends ChangeNotifier {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  bool get initialized => _initialized;

  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  /// True once a rewarded ad is loaded and ready to show.
  bool get rewardedReady => _rewardedAd != null;

  /// Initializes the Mobile Ads SDK and preloads the first rewarded ad.
  /// Safe to call multiple times; only the first call has an effect. A no-op on
  /// unsupported platforms.
  Future<void> initialize() async {
    if (_initialized || !AdConfig.adsSupported) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
      loadRewarded();
    } catch (e) {
      debugPrint('AdService: SDK init failed: $e');
    }
  }

  /// Preloads a rewarded ad so it can be shown instantly. Called after init and
  /// again after each show so the next hint is always ready.
  void loadRewarded() {
    if (!AdConfig.adsSupported || _loadingRewarded || _rewardedAd != null) {
      return;
    }
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewarded = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loadingRewarded = false;
          debugPrint('AdService: rewarded load failed: $error');
          notifyListeners();
        },
      ),
    );
  }

  /// Shows the preloaded rewarded ad. [onReward] fires once the user earns the
  /// reward. Returns false (and does nothing) if no ad is ready. A fresh ad is
  /// preloaded afterward so the next request is instant.
  bool showRewarded({required VoidCallback onReward}) {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewarded(); // kick off a load for next time
      return false;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        notifyListeners();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        debugPrint('AdService: rewarded show failed: $error');
        notifyListeners();
        loadRewarded();
      },
    );

    _rewardedAd = null; // consumed
    notifyListeners();
    ad.show(onUserEarnedReward: (_, _) => onReward());
    return true;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}
