import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const green = Color(0xFF1A3C34);
  static const greenLight = Color(0xFF2D6A5A);
  static const gold = Color(0xFFC9A84C);
  static const cream = Color(0xFFF4EFE4);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFF6B6B6B);
  static const divider = Color(0xFFDDD8CD);

  // Score colors
  static const eagle = Color(0xFFFFD700);
  static const birdie = Color(0xFFFFA500);
  static const par = Color(0xFF1A3C34);
  static const bogey = Color(0xFF8B0000);
  static const doubleBogeyPlus = Color(0xFF5C0000);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.green,
      onPrimary: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.green,
      error: Color(0xFFB00020),
      onError: AppColors.white,
      surface: AppColors.cream,
      onSurface: AppColors.textDark,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    useMaterial3: true,
  );

  final textTheme =
      GoogleFonts.barlowCondensedTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.barlowCondensed(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      color: AppColors.green,
      letterSpacing: 1.5,
    ),
    displayMedium: GoogleFonts.barlowCondensed(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: AppColors.green,
      letterSpacing: 1.2,
    ),
    headlineLarge: GoogleFonts.barlowCondensed(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.green,
      letterSpacing: 1.0,
    ),
    headlineMedium: GoogleFonts.barlowCondensed(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.green,
    ),
    titleLarge: GoogleFonts.barlowCondensed(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
      letterSpacing: 0.5,
    ),
    titleMedium: GoogleFonts.barlowCondensed(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    bodyLarge: GoogleFonts.barlowCondensed(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textDark,
    ),
    bodyMedium: GoogleFonts.barlowCondensed(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textDark,
    ),
    labelLarge: GoogleFonts.barlowCondensed(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.white,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.barlowCondensed(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 1.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.green,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: Color(0xFF8FBFB3),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.barlowCondensed(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.green, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.barlowCondensed(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.green,
    ),
    cardTheme: CardTheme(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      ),
      labelStyle: GoogleFonts.barlowCondensed(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
