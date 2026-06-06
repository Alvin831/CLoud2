import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF242424);
  static const Color card = Color(0xFF1E1E1E);

  // Accent - Neon Green (billiard table feel)
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonGreenDim = Color(0xFF00C853);
  static const Color neonBlue = Color(0xFF00B0FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF666666);

  // Status
  static const Color rating = Color(0xFFFFD740);
  static const Color open = Color(0xFF00E676);
  static const Color closed = Color(0xFFFF5252);

  // Divider
  static const Color divider = Color(0xFF2A2A2A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.neonBlue,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
