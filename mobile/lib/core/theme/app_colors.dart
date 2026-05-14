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
  static const Color skyBlue = Color(0xFF0088FF);      // Splash / Hero backgrounds
  static const Color paleBlue = Color(0xFFD3E3FD);     // Soft cards / Insights
  static const Color iconBlue = Color(0xFF4A89F3);     // Icon outlines / Secondary

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  // Warm amber — used for highlights, badges, and CTAs
  static const Color accent = Color(0xFFFF9500);
  static const Color accentLight = Color(0xFFFFB443);

  // ─── Background Colors ────────────────────────────────────────────────────
  // Light mode backgrounds
  static const Color background = Color(0xFFFFFFFF);      // Main app background
  static const Color surface = Color(0xFFFFFFFF);         // Card surface
  static const Color surfaceElevated = Color(0xFFF1F3F4); // Inputs / elevated elements
  static const Color surfaceBorder = Color(0xFFE8EAED);   // Borders / dividers

  // ─── Text Colors ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212427);     // Main headings / primary text
  static const Color textSecondary = Color(0xFF808489);   // Subtitles / secondary
  static const Color textHint = Color(0xFFAAAAAA);        // Placeholders / hints
  static const Color textDisabled = Color(0xFFC5C7CA);    // Disabled text

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);         // Confirmed, OK
  static const Color error = Color(0xFFEF4444);           // Error states
  static const Color warning = Color(0xFFF59E0B);         // Warnings / alerts
  static const Color info = Color(0xFF3B82F6);            // Info messages

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
    colors: [Color(0xFF0066FF), Color(0xFF0088FF)],
  );

  // Subtle card gradient for depth
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );
}
