import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  AdService._();
  static final AdService instance = AdService._();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;

  static String get _bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    return 'ca-app-pub-3940256099942544/1712485313';
  }

  BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;
  bool get isRewardedLoaded => _isRewardedLoaded;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadBanner();
    loadRewarded();
  }

  void loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
        },
      ),
    )..load();
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _isRewardedLoaded = false;
        },
      ),
    );
  }

  void showRewarded({required VoidCallback onRewarded}) {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        notifyListeners();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        notifyListeners();
        loadRewarded();
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onRewarded(),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
