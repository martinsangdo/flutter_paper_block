import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Central place for every AdMob identifier the app uses.
///
/// **Debug builds** use Google's official *test* ad unit IDs — they always
/// return a test ad (guaranteed fill on emulators/simulators) and never risk an
/// AdMob policy strike for invalid traffic. **Release builds** use the real ad
/// unit IDs from the AdMob console below.
///
/// This split means the emulator always shows a (test) banner during
/// development, while shipped builds serve the real, revenue-earning units.
///
/// ⚠️ TODO(before release): the real *ad unit* IDs below are live. Also set the
/// real *app* IDs in `android/app/src/main/AndroidManifest.xml` (meta-data
/// `com.google.android.gms.ads.APPLICATION_ID`) and `ios/Runner/Info.plist`
/// (`GADApplicationIdentifier`).
///
/// See https://developers.google.com/admob/flutter/test-ads for the test IDs.
class AdConfig {
  AdConfig._();

  /// Anchored adaptive banner unit. Test unit in debug, real unit in release.
  static String get bannerUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      // Google's official sample banner unit — always fills with a test ad.
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isAndroid) return 'ca-app-pub-8762959223087619/8080646472';
    if (Platform.isIOS) return 'ca-app-pub-8762959223087619/8080646472';
    return '';
  }

  /// Rewarded ad unit (used to unlock a gameplay hint). Test in debug, real in
  /// release.
  static String get rewardedUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      // Google's official sample rewarded unit — always fills with a test ad.
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    if (Platform.isAndroid) return 'ca-app-pub-8762959223087619/1120486452';
    if (Platform.isIOS) return 'ca-app-pub-8762959223087619/1120486452';
    return '';
  }

  /// Whether ads are supported on the current platform. Ads are disabled on
  /// web and any non-mobile target.
  static bool get adsSupported {
    if (kIsWeb) return false;
    return false; // TEMP: disabled for clean store screenshots — revert to `Platform.isAndroid || Platform.isIOS`.
  }
}
