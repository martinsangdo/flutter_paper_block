import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Reserves the on-screen region for an AdMob **Anchored Adaptive Banner** so
/// the gameplay layout does not shift when a real ad is wired in later.
///
/// This is a PLACEHOLDER only — no AdMob SDK is integrated yet. It draws a
/// bordered, labelled box the same size the real banner will occupy.
///
/// Anchored adaptive banners span the full device width; their height is a
/// function of the screen height per Google's formula (see [heightFor]).
///
/// To go live later, keep this widget's position in the tree and swap the body
/// of [build] for an `AdWidget(ad: bannerAd)`, sizing the `BannerAd` with
/// `AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width)`. No gameplay
/// code needs to change.
///
/// Ads are disabled on **web**: this renders nothing (zero height) there.
class BannerAdPlaceholder extends StatelessWidget {
  const BannerAdPlaceholder({super.key});

  /// Approximates Google's anchored adaptive banner height: full width, and a
  /// height that is 15% of the screen height, clamped to the SDK's 50–90 dp
  /// band ("never larger than 15% of the device's height or 90 dp, whichever is
  /// smaller, and never smaller than 50 dp"). Replace with
  /// `AdSize.getAnchoredAdaptiveBannerAdSize(...)` when integrating real ads.
  static double heightFor(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.15).clamp(50.0, 90.0);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink(); // ads disabled on web

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: heightFor(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EAD8),
          border: Border.all(color: const Color(0xFFBBA98A), width: 1),
        ),
        child: const Text(
          '[Banner Ad Placeholder]',
          style: TextStyle(
            color: Color(0xFF8B7355),
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
