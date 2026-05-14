// app_text_styles.dart — FLIGHTLY Typography
// Inter font throughout (loaded via google_fonts package)
// WHY: Consistent typography creates visual hierarchy and brand identity

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Display (Hero headings) ──────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.dmSans(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // ─── Headings ────────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headingMedium => GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle get headingSmall => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Body Text ────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Labels ───────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ─── Specialized ──────────────────────────────────────────────────────────
  // Price display — large and prominent
  static TextStyle get priceDisplay => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  );

  // Booking reference — monospace-style for readability
  static TextStyle get bookingRef => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 2.0,
  );

  // Input field text
  static TextStyle get inputText => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Button text
  static TextStyle get button => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static TextStyle get buttonSmall => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
  );

  // ─── Flight Data Styles ────────────────────────────────────────────────────
  // Departure / arrival times — large and scannable
  static TextStyle get timeDisplay => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.3,
  );

  // Primary price display — dominant, blue
  static TextStyle get priceLarge => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.1,
    letterSpacing: -0.3,
  );

  // Secondary price — smaller but still bold
  static TextStyle get priceSmall => GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );

  // Section group headers — uppercase, spaced, subtle
  static TextStyle get sectionLabel => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.8,
  );
}
