import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'route_observer.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.instance.load();
  // Fire-and-forget: the Mobile Ads SDK initializes in the background so it
  // never delays the splash/first frame. Ads simply appear once it's ready.
  unawaited(AdService.instance.initialize());
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const PaperBlockApp());
}

class PaperBlockApp extends StatelessWidget {
  const PaperBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper Blocks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE85D75),
          surface: Color(0xFFF5F0E8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
    );
  }
}
