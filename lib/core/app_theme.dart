import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFFAF6EF);
  static const header = Color(0xFFF3ECDF);
  static const primary = Color(0xFFE07856);
  static const green = Color(0xFF3D8B57);
  static const orange = Color(0xFFA67C2E);
  static const red = Color(0xFFD9534A);
  static const blue = Color(0xFF5B8A9E);
  static const purple = Color(0xFF9B7EBD);
  static const text = Color(0xFF2D2A26);
  static const muted = Color(0xFF8A7F72);
  static const line = Color(0xFFEDE4D3);
  static const card = Color(0xFFFFFDF8);
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
