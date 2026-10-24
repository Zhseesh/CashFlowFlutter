import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const emerald = Color(0xFF115E59);
  static const mint = Color(0xFF10B981);
  static const rose = Color(0xFFE11D48);
  static const slate900 = Color(0xFF0F172A);
  static const slate50 = Color(0xFFF8FAFC);

  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFE11D48);
}

/// "#RRGGBB" -> Color (abu-abu bila tidak valid).
Color hexToColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? const Color(0xFF64748B) : Color(v);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: brightness,
  ).copyWith(
    primary: dark ? AppColors.mint : AppColors.emerald,
    secondary: AppColors.rose,
    surface: dark ? AppColors.slate900 : AppColors.slate50,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primary.withAlpha(40),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: dark ? AppColors.slate900 : Colors.white,
    ),
  );
}

/// Gaya angka nominal: semi-bold dengan angka tabular agar mudah dibaca.
TextStyle amountStyle(BuildContext context, {double size = 16, Color? color}) {
  return TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );
}
