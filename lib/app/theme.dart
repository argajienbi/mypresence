import 'package:flutter/material.dart';

/// Palet "Bahasa MyAdmin" — diselaraskan dengan lib/core/app_theme.dart
/// (primer teal #0b7a8c, aksen coral, gelap #0b2b33, radius 10px).
/// Nama field dipertahankan agar kompatibel dengan 5 file konsumen.
class AppColors {
  static const background = Color(0xFFF1F5F9);
  static const headerCurve = Color(0xFF0B7A8C);
  static const primary = Color(0xFF0B7A8C);
  static const primaryDark = Color(0xFF0B2B33);
  static const green = Color(0xFF16A34A);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFDC2626);
  static const blue = Color(0xFF0B7A8C);
  static const purple = Color(0xFF7C3AED);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8F0);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.green,
        surface: AppColors.card,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
