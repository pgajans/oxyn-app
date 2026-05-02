import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/app_localizations.dart';

const _kLocaleKey = 'app_locale';

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLocaleKey);
      if (code != null && code.isNotEmpty) {
        final loc = Locale(code);
        if (AppLocalizations.supportedLocales.contains(loc)) {
          state = loc;
        }
      }
    } catch (e) {
      debugPrint('LocaleNotifier load error: $e');
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_kLocaleKey);
      } else {
        await prefs.setString(_kLocaleKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('LocaleNotifier save error: $e');
    }
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

Locale resolveInitialLocale(
  Iterable<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  if (deviceLocales != null) {
    for (final dev in deviceLocales) {
      for (final sup in supported) {
        if (dev.languageCode == sup.languageCode) return sup;
      }
    }
  }
  return const Locale('en');
}
