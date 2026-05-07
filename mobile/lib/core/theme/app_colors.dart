// app_colors.dart — FLIGHTLY Color Palette
// Centralized color constants used throughout the entire app
// WHY: Having one source of truth prevents inconsistent colors across screens

import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation — static class only
  AppColors._();

  // ─── Brand Color Palette (User Requested) ──────────────────────────────────
  
  /// Primary Action Blue - Used for primary buttons, active states, main UI
  static const Color primaryBlue = Color(0xFF0066FF);
  
  /// Splash Screen Sky Blue - Lighter blue for large backgrounds/splash screens
  static const Color skyBlue = Color(0xFF0088FF);

  // 🖌️ Secondary & Accent Blues
  /// Iconography Outline Blue - Used for custom icon borders and structural lines
  static const Color iconOutlineBlue = Color(0xFF4A89F3);
  
  /// Pale Ice Blue - Soft background canvas for icons and illustration blobs
  static const Color paleIceBlue = Color(0xFFD3E3FD);

  // ⚖️ Neutrals & Typography
  /// Dark Ink / Charcoal - Primary text color, character outlines, dark elements
  static const Color darkInk = Color(0xFF212427);
  
  /// Subtitle Gray - Secondary text, descriptions, placeholders
  static const Color subtitleGray = Color(0xFF808489);
  
  /// UI Light Gray - Subtle UI elements, input field backgrounds, borders
  static const Color lightGray = Color(0xFFF1F3F4);
  
  /// Pure White - Base background color and text on primary buttons
  static const Color white = Color(0xFFFFFFFF); 

  // ─── Functional Aliases ───────────────────────────────────────────────────
  // Mapping brand colors to functional roles used in the app logic
  
  static const Color primary = primaryBlue;
  static const Color primaryLight = skyBlue;
  static const Color primaryDark = Color(0xFF0052CC);

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  static const Color accent = iconOutlineBlue;
  static const Color accentLight = paleIceBlue;

  // ─── Background & Surface ─────────────────────────────────────────────────
  // Updated to reflect the new Light Theme palette
  static const Color background = white;      
  static const Color surface = lightGray;          
  static const Color surfaceElevated = white;  
  static const Color surfaceBorder = Color(0xFFE8EAED); // Subtle border

  // ─── Text Colors ──────────────────────────────────────────────────────────
  static const Color textPrimary = darkInk;      
  static const Color textSecondary = subtitleGray;         
  static const Color textHint = Color(0xFFB0B3B8);         
  static const Color textDisabled = Color(0xFFD2D5D8);     

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);          
  static const Color error = Color(0xFFEF4444);            
  static const Color warning = Color(0xFFF59E0B);          
  static const Color info = primaryBlue;             

  // ─── Badge / Label Colors ────────────────────────────────────────────────
  static const Color badgeBest = Color(0xFF7C3AED);       // "Best" badge (purple)
  static const Color badgeCheapest = Color(0xFF059669);   // "Cheapest" badge (green)
  static const Color badgeFastest = Color(0xFF2563EB);    // "Fastest" badge (blue)
  static const Color badgeValue = Color(0xFFD97706);      // "Value" badge (amber)

  // ─── Common ───────────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF7C3AED)], // Mixing in a purple for depth
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, lightGray],
  );
}
