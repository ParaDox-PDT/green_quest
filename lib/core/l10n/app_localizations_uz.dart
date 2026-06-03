// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Yashil Sarguzasht';

  @override
  String get startGame => 'O\'yinni Boshlash';

  @override
  String get selectLanguage => 'Til';

  @override
  String get selectCharacter => 'Qahramonni tanlang';

  @override
  String get characterFox => 'Tulkicha';

  @override
  String get characterRabbit => 'Quyoncha';

  @override
  String get characterBear => 'Ayiqcha';

  @override
  String get characterSquirrel => 'Moshqutvoy';

  @override
  String get rollDice => 'Toshni otish';

  @override
  String get turnStatus => 'Sizning galingiz';

  @override
  String tileStatus(int number) {
    return 'Katakcha $number';
  }

  @override
  String get eventNap =>
      'Katta daraxt ostida uxlab qoldingiz. Navbatni o\'tkazish!';

  @override
  String eventWind(int spaces) {
    return 'Yoqimli shamol esdi! $spaces katak oldinga.';
  }

  @override
  String get eventClover => 'To\'rt bargli beda topdingiz! Qo\'shimcha gal!';

  @override
  String eventFog(int spaces) {
    return 'Qalin tumanda adashib qoldingiz! $spaces katak orqaga.';
  }

  @override
  String get eventStart => 'Adashib qolib, boshlang\'ich nuqtaga qaytdingiz!';

  @override
  String get victoryMessage =>
      'Tabriklaymiz! Siz O\'rmon maskaniga yetib keldingiz!';

  @override
  String get defeatMessage =>
      'Afsuski, marraga yetolmadingiz. Qayta urinib ko\'ring!';

  @override
  String get playAgain => 'Qaytadan o\'ynash';

  @override
  String get mainMenu => 'Asosiy menyu';
}
