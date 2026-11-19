import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================
/// NEO-BRUTALISM DESIGN TOKENS
/// ============================================

class NeoColors {
  // Palette "sticker" — universal di light & dark
  static const yellow = Color(0xFFFFE566);
  static const pink = Color(0xFFFF6B9D);
  static const cyan = Color(0xFF5CE1E6);
  static const lime = Color(0xFFC4F55C);
  static const purple = Color(0xFFC8A2FF);
  static const orange = Color(0xFFFFA45C);
  static const red = Color(0xFFFF5757);
  static const green = Color(0xFF2BA84A);

  // Light
  static const inkLight = Color(0xFF0A0A0A);
  static const paperLight = Color(0xFFFFFDF5);
  static const canvasLight = Color(0xFFF0EDE3);

  // Dark
  static const inkDark = Color(0xFFFFFFFF);
  static const paperDark = Color(0xFF1A1A1A);
  static const canvasDark = Color(0xFF0F0F0F);
}

/// Helper yang theme-aware
class Neo {
  static Color ink(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color paper(BuildContext c) => Theme.of(c).colorScheme.surface;
  static Color canvas(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;
}

class NeoRadius {
  static const sm = 10.0;
  static const reg = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class NeoText {
  static TextStyle display(double size, {Color? color}) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.3,
      );

  static TextStyle label(double size, {Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      );
}

class NeoBorders {
  static Border thin(Color ink) => Border.all(color: ink, width: 2);
  static Border reg(Color ink) => Border.all(color: ink, width: 3);
  static Border thick(Color ink) => Border.all(color: ink, width: 4);
}

class NeoShadows {
  static List<BoxShadow> sm(Color ink) =>
      [BoxShadow(color: ink, offset: const Offset(4, 4), blurRadius: 0)];
  static List<BoxShadow> md(Color ink) =>
      [BoxShadow(color: ink, offset: const Offset(6, 6), blurRadius: 0)];
  static List<BoxShadow> lg(Color ink) =>
      [BoxShadow(color: ink, offset: const Offset(8, 8), blurRadius: 0)];
}

/// ============================================
/// THEME BUILDER
/// ============================================

ThemeData buildNeoTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final ink = isDark ? NeoColors.inkDark : NeoColors.inkLight;
  final paper = isDark ? NeoColors.paperDark : NeoColors.paperLight;
  final canvas = isDark ? NeoColors.canvasDark : NeoColors.canvasLight;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: NeoColors.yellow,
      onPrimary: NeoColors.inkLight,
      secondary: NeoColors.pink,
      onSecondary: NeoColors.inkLight,
      tertiary: NeoColors.cyan,
      onTertiary: NeoColors.inkLight,
      error: NeoColors.red,
      onError: Colors.white,
      surface: paper,
      onSurface: ink,
    ),

    // ── APP BAR ─────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: ink, width: 3)),
      titleTextStyle: NeoText.display(20, color: ink),
      iconTheme: IconThemeData(color: ink),
    ),

    // ── DIVIDER ─────────────────────────────────────────
    dividerTheme: DividerThemeData(color: ink, thickness: 2, space: 2),

    // ── RIPPLE (disable) ────────────────────────────────
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,

    // ── SNACKBAR ────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle:
          NeoText.body(13, weight: FontWeight.w600, color: paper),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoRadius.reg),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      actionTextColor: NeoColors.yellow,
      insetPadding: const EdgeInsets.all(16),
    ),

    // ── POPUP MENU (dropdown appearance/language) ───────
    popupMenuTheme: PopupMenuThemeData(
      color: paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoRadius.reg),
        side: BorderSide(color: ink, width: 3),
      ),
      textStyle: NeoText.body(13, weight: FontWeight.w600, color: ink),
      labelTextStyle: WidgetStatePropertyAll(
        NeoText.body(13, weight: FontWeight.w600, color: ink),
      ),
    ),

    // ── DIALOG (fallback showDialog default) ────────────
    dialogTheme: DialogThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoRadius.lg),
        side: BorderSide(color: ink, width: 3),
      ),
      titleTextStyle: NeoText.display(16, color: ink),
      contentTextStyle: NeoText.body(13, color: ink),
    ),

    // ── TOOLTIP ─────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: NeoText.body(11, weight: FontWeight.w600, color: paper),
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // ── INPUT (NeoInput custom tetap override) ──────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paper,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoRadius.reg),
        borderSide: BorderSide(color: ink, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoRadius.reg),
        borderSide: const BorderSide(color: NeoColors.yellow, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoRadius.reg),
        borderSide: const BorderSide(color: NeoColors.red, width: 3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoRadius.reg),
        borderSide: const BorderSide(color: NeoColors.red, width: 3),
      ),
    ),

    // ── TEXT SELECTION ──────────────────────────────────
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ink,
      selectionColor: NeoColors.yellow.withValues(alpha: 0.5),
      selectionHandleColor: ink,
    ),
  );
}