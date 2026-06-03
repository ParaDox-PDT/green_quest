// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Зелёный Квест';

  @override
  String get startGame => 'Начать игру';

  @override
  String get selectLanguage => 'Язык';

  @override
  String get selectCharacter => 'Выбери персонажа';

  @override
  String get characterFox => 'Лисёнок';

  @override
  String get characterRabbit => 'Зайчонок';

  @override
  String get characterBear => 'Медвежонок';

  @override
  String get characterSquirrel => 'Бельчонок';

  @override
  String get rollDice => 'Бросить кубик';

  @override
  String get turnStatus => 'Ваш ход';

  @override
  String tileStatus(int number) {
    return 'Клетка $number';
  }

  @override
  String get eventNap => 'Решили вздремнуть под деревом. Пропуск хода!';

  @override
  String eventWind(int spaces) {
    return 'Попутный ветерок подхватил вас! Вперед на $spaces кл.';
  }

  @override
  String get eventClover =>
      'Нашли счастливый четырехлистный клевер! Дополнительный ход!';

  @override
  String eventFog(int spaces) {
    return 'Заблудились в густом тумане! Назад на $spaces кл.';
  }

  @override
  String get eventStart => 'Вы заблудились и вернулись на Старт!';

  @override
  String get victoryMessage => 'Поздравляем! Вы добрались до Лесной Гавани!';

  @override
  String get defeatMessage =>
      'О нет! Локальные испытания обошли вас. Попробуйте еще раз!';

  @override
  String get playAgain => 'Играть снова';

  @override
  String get mainMenu => 'Главное меню';
}
