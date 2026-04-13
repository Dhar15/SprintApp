import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color background     = Color(0xFF080810);
  static const Color surface        = Color(0xFF11111E);
  static const Color surfaceElevated = Color(0xFF191927);
  static const Color border         = Color(0xFF252536);
  static const Color borderBright   = Color(0xFF363650);

  // Word Sprint — indigo-violet
  static const Color wordAccent     = Color(0xFF8B7FFF);
  static const Color wordAccentSoft = Color(0xFF6C5FE8);
  static const Color wordGlow       = Color(0x308B7FFF);
  static const Color wordSurface    = Color(0xFF161628);

  // News Sprint — sunrise amber-orange
  static const Color newsAccent     = Color(0xFFFF8C42);
  static const Color newsAccentSoft = Color(0xFFE06A20);
  static const Color newsGlow       = Color(0x30FF8C42);
  static const Color newsSurface    = Color(0xFF1E1510);

  // Semantic
  static const Color success        = Color(0xFF34D399);
  static const Color successGlow    = Color(0x2534D399);
  static const Color error          = Color(0xFFFF5C7C);
  static const Color warning        = Color(0xFFFFBF47);

  // Text
  static const Color textPrimary    = Color(0xFFF2F2FA);
  static const Color textSecondary  = Color(0xFF8B8BAD);
  static const Color textTertiary   = Color(0xFF3E3E5C);

  // Accent (global)
  static const Color accent         = Color(0xFF34D399);
  static const Color accentGlow     = Color(0x2234D399);

  // Gradient stops
  static const Color gradWordStart  = Color(0xFF8B7FFF);
  static const Color gradWordEnd    = Color(0xFF5B4FD8);
  static const Color gradNewsStart  = Color(0xFFFF8C42);
  static const Color gradNewsEnd    = Color(0xFFE0401A);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.wordAccent,
        error: AppColors.error,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.background,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        displaySmall: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
        headlineLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.65,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.6,
        ),
        labelLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}