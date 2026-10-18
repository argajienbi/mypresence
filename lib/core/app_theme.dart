import 'package:flutter/material.dart';

/// Palet "Fintech Fusion" — kombinasi BRIMO (biru profesional),
/// Shopee (oranye energik), Jago (minimalis bersih), Kredivo (kartu rapi).
/// Dikunci 2026-10-19 sesuai mockup ~/workspace/mockup-fintech/.
class AppColors {
  // Brand
  static const primary = Color(0xFF0B5ED7);
  static const primaryDark = Color(0xFF084298);
  static const primarySoft = Color(0xFFE3EEFD);
  static const accent = Color(0xFFFF6B35);
  static const accentDark = Color(0xFFE8590C);
  static const accentSoft = Color(0xFFFFEDE4);

  // Surface
  static const bg = Color(0xFFF1F5F9);
  static const header = Color(0xFF0B5ED7);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8F0);

  // Text
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);

  // Status
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const orange = Color(0xFFF59E0B);
  static const orangeSoft = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEE2E2);
  static const blue = Color(0xFF0B5ED7);
  static const blueSoft = Color(0xFFE3EEFD);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFEDE9FE);

  // Header gradient (BRIMO style)
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B5ED7), Color(0xFF084298)],
  );
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
        secondary: AppColors.accent,
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
    );
  }
}

class AppText {
  static const title = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text);
  static const subtitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const bodyBold = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text);
  static const body = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text);
}
