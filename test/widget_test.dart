import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_quest/main.dart';
import 'package:green_quest/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('App launches and displays Splash Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GreenQuestApp(),
      ),
    );

    // Verify that the SplashScreen is present
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify that the app title exists (default language is English, so "Green Quest")
    expect(find.text('Green Quest'), findsOneWidget);
  });
}
