import 'dart:async';
import 'package:flutter/material.dart';
import 'main_menu_screen.dart';

/// White splash with a centered logo, shown for exactly 2 seconds before
/// navigating to the main menu. The logo (and any next-screen assets) are
/// precached during the wait so the transition has no first-frame jank.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const AssetImage logo = AssetImage('assets/logo.png');

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    // Fixed 2-second display, independent of how fast precaching finishes.
    _timer = Timer(const Duration(seconds: 2), _goToHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Warm the image cache while the splash is visible. The main menu itself
    // draws only vector/colored widgets (no bitmaps), so the logo is the only
    // asset that needs decoding ahead of the transition.
    precacheImage(SplashScreen.logo, context);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => const MainMenuScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: SplashScreen.logo,
          width: 180,
          height: 180,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
