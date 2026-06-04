import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';
import 'package:green_quest/features/menu/presentation/main_menu_screen.dart';
import 'package:green_quest/core/providers/locale_provider.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final locale = ref.watch(localeProvider);
          return MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
              Locale('uz'),
            ],
            home: const MainMenuScreen(),
          );
        },
      ),
    );
  }

  testWidgets('MainMenuScreen renders title and default English language', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify Title and Subtitle exist
    expect(find.text('Green Quest'), findsOneWidget);
    expect(find.text('Select Your Character'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
  });

  testWidgets('Selecting language updates UI text dynamically', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Initially English
    expect(find.text('Select Your Character'), findsOneWidget);

    // Tap 'EN' to open language popup menu
    final enTrigger = find.text('EN');
    expect(enTrigger, findsOneWidget);
    await tester.tap(enTrigger);
    await tester.pumpAndSettle();

    // Tap 'Oʻzbekcha' menu item
    final uzItem = find.text('Oʻzbekcha');
    expect(uzItem, findsOneWidget);
    await tester.tap(uzItem);
    await tester.pumpAndSettle();

    // Text should change to Uzbek
    expect(find.text('Qahramonni tanlang'), findsOneWidget);
    expect(find.text('O\'yinni Boshlash'), findsOneWidget);

    // Tap 'UZ' to open language popup menu again
    final uzTrigger = find.text('UZ');
    expect(uzTrigger, findsOneWidget);
    await tester.tap(uzTrigger);
    await tester.pumpAndSettle();

    // Tap 'Русский' menu item
    final ruItem = find.text('Русский');
    expect(ruItem, findsOneWidget);
    await tester.tap(ruItem);
    await tester.pumpAndSettle();

    // Text should change to Russian
    expect(find.text('Выбери персонажа'), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
  });

  testWidgets('Play button is disabled until character is chosen', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify Start Game button is initially disabled (opacity is checked implicitly in code, or we can check onPressed callback)
    final startButtonFinder = find.byKey(const Key('start_game_button'));
    ElevatedButton startButton = tester.widget<ElevatedButton>(startButtonFinder);
    expect(startButton.onPressed, isNull); // disabled

    // Select the Fox character (should find 'Fox' text card)
    final foxCard = find.text('Fox');
    expect(foxCard, findsOneWidget);
    await tester.tap(foxCard);
    await tester.pumpAndSettle();

    // The Start Game button should now be enabled
    startButton = tester.widget<ElevatedButton>(startButtonFinder);
    expect(startButton.onPressed, isNotNull); // enabled
  });
}
