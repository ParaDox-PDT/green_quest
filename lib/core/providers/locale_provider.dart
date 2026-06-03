import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to read and watch the current locale of the application.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// A state notifier that manages the app locale.
/// Supports 'en', 'ru', and 'uz' language codes.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  /// Updates the active locale with safety check.
  void setLocale(Locale locale) {
    if (const ['en', 'ru', 'uz'].contains(locale.languageCode)) {
      state = locale;
    }
  }

  /// Helper to update locale by language code string.
  void setLanguageCode(String code) {
    setLocale(Locale(code));
  }
}
