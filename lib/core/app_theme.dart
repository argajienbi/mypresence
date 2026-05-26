import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFEAF8FA);
  static const header = Color(0xFFDDF5FA);
  static const primary = Color(0xFF0E8FA3);
  static const green = Color(0xFF2ECC71);
  static const orange = Color(0xFFF5A623);
  static const red = Color(0xFFE74C3C);
  static const blue = Color(0xFF1E9BD7);
  static const purple = Color(0xFF8E44AD);
  static const text = Color(0xFF1F2933);
  static const muted = Color(0xFF6B7C8F);
  static const line = Color(0xFFE5E7EB);
  static const card = Colors.white;
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.primary,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.green,
        surface: AppColors.card,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
            inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class AppText {
  static const title = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text);
  static const subtitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const bodyBold = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text);
  static const body = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text);
}
