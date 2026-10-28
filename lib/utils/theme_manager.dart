import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  ThemeManager._();
  
  // Default ke system (mengikuti HP)
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  
  static const _key = 'theme_mode';

  /// Dipanggil saat aplikasi pertama kali dibuka
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    
    if (saved == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (saved == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  /// Dipanggil saat tombol tema ditekan
  static Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Logika: Light -> Dark -> System -> Light
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
      await prefs.setString(_key, 'dark');
    } else if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.system;
      await prefs.setString(_key, 'system');
    } else {
      themeMode.value = ThemeMode.light;
      await prefs.setString(_key, 'light');
    }
  }
}