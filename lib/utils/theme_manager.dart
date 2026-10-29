import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  ThemeManager._();
  
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('id'));
  
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'app_locale';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }

    // Load Locale
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale == 'en') {
      locale.value = const Locale('en');
    } else {
      locale.value = const Locale('id');
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  static Future<void> setLocale(String langCode) async {
    locale.value = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, langCode);
  }
}