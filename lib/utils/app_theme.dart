import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceHover = Color(0xFF2A2A2A);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    colorScheme: ColorScheme.fromSeed(
      seedColor: emerald500,
      primary: emerald500,
      secondary: emerald600,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    // PERBAIKAN: Casting TextTheme ke material_ui
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme) as TextTheme?,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF3F4F6),
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1D5DB))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1D5DB))),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: emerald500, width: 1.5)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: emerald500,
      primary: emerald500,
      secondary: emerald600,
      surface: darkSurface,
      brightness: Brightness.dark,
    ),
    // PERBAIKAN: Casting TextTheme ke material_ui
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme) as TextTheme?,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4B5563))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4B5563))),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: emerald500, width: 1.5)),
    ),
  );
}