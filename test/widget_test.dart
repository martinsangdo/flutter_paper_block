// Basic smoke test: the app opens on the splash screen and, after the
// 2-second delay, auto-navigates to the main menu.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_block_game/main.dart';
import 'package:paper_block_game/screens/splash_screen.dart';

void main() {
  testWidgets('Splash shows, then navigates to the menu',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const PaperBlockApp());

    // Splash is the first screen.
    expect(find.byType(SplashScreen), findsOneWidget);

    // After exactly 2 seconds it auto-navigates to the main menu.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
