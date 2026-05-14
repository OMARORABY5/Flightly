// app_theme.dart — FLIGHTLY Full ThemeData
// Configures the entire Material 3 light theme for the app
// WHY: Centralizing theme prevents scattered styling and ensures consistency

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ─── Color Scheme ────────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),

      // ─── Scaffold Background ─────────────────────────────────────────────
      // #F1F3F4 UI Light Gray — now the universal app background
      scaffoldBackgroundColor: AppColors.background,

      // ─── Typography ───────────────────────────────────────────────────────
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // ─── AppBar ──────────────────────────────────────────────────────────
      // White bar floats over the gray background — visible separation
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.headingMedium,
        shadowColor: Colors.black12,
      ),

      // ─── Card ─────────────────────────────────────────────────────────────
      // Pure white cards lift from the gray background naturally
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black,
      ),

      // ─── Input Fields ─────────────────────────────────────────────────────
      // White fill + visible border so inputs stand out on gray background
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface, // Pure white — visible on #F1F3F4 gray
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),

      // ─── Elevated Button ──────────────────────────────────────────────────
      // Subtle blue shadow gives buttons depth on the gray background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.35),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ─── Outlined Button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),

      // ─── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),

      // ─── Bottom Navigation Bar ───────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ─── Chip (filter tags) ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.paleBlue,
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),

      // ─── Icon ────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // ─── Page Transitions ─────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
