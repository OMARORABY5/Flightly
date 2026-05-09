// app_colors.dart — FLIGHTLY Color Palette
// Centralized color constants used throughout the entire app
// WHY: Having one source of truth prevents inconsistent colors across screens

import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation — static class only
  AppColors._();

  // ─── Primary Brand Colors ─────────────────────────────────────────────────
  // Deep sky blue — conveys trust, aviation, and sky
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryLight = Color(0xFF3D8BFF);
  static const Color primaryDark = Color(0xFF0047CC);

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  // Warm amber — used for highlights, badges, and CTAs
  static const Color accent = Color(0xFFFF9500);
  static const Color accentLight = Color(0xFFFFB443);

  // ─── Background Colors ────────────────────────────────────────────────────
  // Dark mode backgrounds (main app uses dark theme)
  static const Color background = Color(0xFF0A0E1A);      // Page background
  static const Color surface = Color(0xFF141927);          // Card surface
  static const Color surfaceElevated = Color(0xFF1E2537);  // Elevated cards
  static const Color surfaceBorder = Color(0xFF2A3347);    // Borders / dividers

  // ─── Text Colors ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F4FF);      // Main text (off-white)
  static const Color textSecondary = Color(0xFF8892A4);    // Secondary / labels
  static const Color textHint = Color(0xFF50596B);         // Placeholders / hints
  static const Color textDisabled = Color(0xFF3A4152);     // Disabled text

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);          // Confirmed, OK
  static const Color error = Color(0xFFEF4444);            // Error states
  static const Color warning = Color(0xFFF59E0B);          // Warnings / alerts
  static const Color info = Color(0xFF3B82F6);             // Info messages

  // ─── Badge / Label Colors ────────────────────────────────────────────────
  static const Color badgeBest = Color(0xFF7C3AED);       // "Best" badge (purple)
  static const Color badgeCheapest = Color(0xFF059669);   // "Cheapest" badge (green)
  static const Color badgeFastest = Color(0xFF2563EB);    // "Fastest" badge (blue)
  static const Color badgeValue = Color(0xFFD97706);      // "Value" badge (amber)

  // ─── Common ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Gradient: hero/home screen gradient overlay
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF7C3AED)],
  );

  // Subtle card gradient for depth
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2537), Color(0xFF141927)],
  );
}
