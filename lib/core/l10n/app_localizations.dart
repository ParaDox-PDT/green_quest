import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// The title of the game
  ///
  /// In en, this message translates to:
  /// **'Green Quest'**
  String get appTitle;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get selectLanguage;

  /// No description provided for @selectCharacter.
  ///
  /// In en, this message translates to:
  /// **'Select Your Character'**
  String get selectCharacter;

  /// No description provided for @characterFox.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get characterFox;

  /// No description provided for @characterRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get characterRabbit;

  /// No description provided for @characterBear.
  ///
  /// In en, this message translates to:
  /// **'Bear'**
  String get characterBear;

  /// No description provided for @characterSquirrel.
  ///
  /// In en, this message translates to:
  /// **'Squirrel'**
  String get characterSquirrel;

  /// No description provided for @rollDice.
  ///
  /// In en, this message translates to:
  /// **'Roll Dice'**
  String get rollDice;

  /// No description provided for @turnStatus.
  ///
  /// In en, this message translates to:
  /// **'Your Turn'**
  String get turnStatus;

  /// No description provided for @tileStatus.
  ///
  /// In en, this message translates to:
  /// **'Tile {number}'**
  String tileStatus(int number);

  /// No description provided for @eventNap.
  ///
  /// In en, this message translates to:
  /// **'Taking a nap under a big tree. Skip a turn!'**
  String get eventNap;

  /// No description provided for @eventWind.
  ///
  /// In en, this message translates to:
  /// **'Caught a friendly wind gust! Advance {spaces} spaces.'**
  String eventWind(int spaces);

  /// No description provided for @eventClover.
  ///
  /// In en, this message translates to:
  /// **'Found a lucky four-leaf clover! Extra turn!'**
  String get eventClover;

  /// No description provided for @eventFog.
  ///
  /// In en, this message translates to:
  /// **'Got lost in the thick fog! Move backward {spaces} spaces.'**
  String eventFog(int spaces);

  /// No description provided for @eventStart.
  ///
  /// In en, this message translates to:
  /// **'Got lost and returned to the Start!'**
  String get eventStart;

  /// No description provided for @victoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached the Forest Haven!'**
  String get victoryMessage;

  /// No description provided for @defeatMessage.
  ///
  /// In en, this message translates to:
  /// **'Oh no! The milestones caught up to you. Try again!'**
  String get defeatMessage;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
