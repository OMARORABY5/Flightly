// helpers.dart — FLIGHTLY General Utilities
// Formatting, date helpers, string utilities used across the app

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flightly/core/constants/app_constants.dart';

class AppHelpers {
  AppHelpers._();

  // ─── Date & Time ──────────────────────────────────────────────────────────

  /// Format DateTime → "Mon, 25 Jan 2025"
  static String formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  /// Format DateTime → "14:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format DateTime → "25 Jan"
  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  /// Convert duration in minutes → "2h 35m"
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// "5 minutes ago", "2 hours ago", etc. for notifications
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(date);
  }

  // ─── Currency / Price ─────────────────────────────────────────────────────

  /// Format price → "1,250 EGP"
  static String formatPrice(double amount, {String currency = 'EGP'}) {
    final formatter = NumberFormat.currency(
      customPattern: '#,##0 $currency',
      symbol: currency,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // ─── Booking Reference ────────────────────────────────────────────────────

  /// Generate a booking reference in format FLY-YYYYMMDD-XXXXXX
  static String generateBookingRef() {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(6, (_) {
      final index = DateTime.now().microsecondsSinceEpoch % chars.length;
      return chars[index];
    }).join();
    return 'FLY-$date-$random';
  }

  // ─── String Utilities ─────────────────────────────────────────────────────

  /// Capitalize first letter of each word
  static String titleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Mask card number: "•••• •••• •••• 4242"
  static String maskCardNumber(String number) {
    final cleaned = number.replaceAll(' ', '');
    if (cleaned.length < 4) return number;
    final last4 = cleaned.substring(cleaned.length - 4);
    return '•••• •••• •••• $last4';
  }

  /// Get cabin class display name
  static String cabinClassName(String code) {
    switch (code.toLowerCase()) {
      case 'economy': return 'Economy';
      case 'premium_economy': return 'Premium Economy';
      case 'business': return 'Business';
      case 'first': return 'First Class';
      default: return code;
    }
  }

  /// Get stop count display text
  static String stopsLabel(int stops) {
    if (stops == 0) return 'Direct';
    if (stops == 1) return '1 Stop';
    return '$stops Stops';
  }

  /// Get image provider for avatar
  static ImageProvider? getAvatarProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    }
    if (url.startsWith('/uploads')) {
      final host = AppConstants.baseUrl.replaceAll('/api', '');
      return CachedNetworkImageProvider('$host$url');
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
