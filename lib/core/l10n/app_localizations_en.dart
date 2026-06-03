// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Green Quest';

  @override
  String get startGame => 'Start Game';

  @override
  String get selectLanguage => 'Language';

  @override
  String get selectCharacter => 'Select Your Character';

  @override
  String get characterFox => 'Fox';

  @override
  String get characterRabbit => 'Rabbit';

  @override
  String get characterBear => 'Bear';

  @override
  String get characterSquirrel => 'Squirrel';

  @override
  String get rollDice => 'Roll Dice';

  @override
  String get turnStatus => 'Your Turn';

  @override
  String tileStatus(int number) {
    return 'Tile $number';
  }

  @override
  String get eventNap => 'Taking a nap under a big tree. Skip a turn!';

  @override
  String eventWind(int spaces) {
    return 'Caught a friendly wind gust! Advance $spaces spaces.';
  }

  @override
  String get eventClover => 'Found a lucky four-leaf clover! Extra turn!';

  @override
  String eventFog(int spaces) {
    return 'Got lost in the thick fog! Move backward $spaces spaces.';
  }

  @override
  String get eventStart => 'Got lost and returned to the Start!';

  @override
  String get victoryMessage => 'Congratulations! You reached the Forest Haven!';

  @override
  String get defeatMessage =>
      'Oh no! The milestones caught up to you. Try again!';

  @override
  String get playAgain => 'Play Again';

  @override
  String get mainMenu => 'Main Menu';
}
