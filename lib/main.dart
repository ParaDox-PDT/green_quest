import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/providers/locale_provider.dart';
import 'package:green_quest/features/splash/presentation/splash_screen.dart';
import 'package:green_quest/core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce landscape orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Enforce full-screen sticky immersive mode (hides system bars)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final container = ProviderContainer();
  final firebaseService = container.read(firebaseServiceProvider);
  await firebaseService.init();
  await firebaseService.signInAnonymously();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GreenQuestApp(),
    ),
  );
}

class GreenQuestApp extends ConsumerWidget {
  const GreenQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Quest',
      theme: GameTheme.lightTheme,
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
      home: const SplashScreen(),
    );
  }
}
