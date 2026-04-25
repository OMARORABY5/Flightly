// validators.dart — FLIGHTLY Input Validators
// Reusable validation functions for forms throughout the app
// WHY: Centralizing validators prevents duplicate logic and ensures
//      the same rules apply everywhere (e.g., same password rules in register and change-password)

import '../constants/app_constants.dart';

class Validators {
  Validators._();

  // ─── Email ────────────────────────────────────────────────────────────────

  /// Returns error string if invalid, null if valid
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // ─── Password ────────────────────────────────────────────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters.';
    }
    return null;
  }

  /// Validates password with full rule set (for registration)
  static List<PasswordRule> passwordRules(String password) {
    return [
      PasswordRule('At least 8 characters', password.length >= 8),
      PasswordRule('One uppercase letter', password.contains(RegExp(r'[A-Z]'))),
      PasswordRule('One lowercase letter', password.contains(RegExp(r'[a-z]'))),
      PasswordRule('One number', password.contains(RegExp(r'[0-9]'))),
      PasswordRule('One special character (!@#\$...)', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
    ];
  }

  /// Returns error if passwords don't match
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != original) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // ─── Name ─────────────────────────────────────────────────────────────────

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  // ─── Passport ────────────────────────────────────────────────────────────

  static String? passportNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Passport number is required.';
    }
    final cleaned = value.trim().toUpperCase();
    if (cleaned.length < AppConstants.passportMinLength ||
        cleaned.length > AppConstants.passportMaxLength) {
      return 'Passport must be ${AppConstants.passportMinLength}–${AppConstants.passportMaxLength} characters.';
    }
    // Alphanumeric only
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned)) {
      return 'Passport may only contain letters and numbers.';
    }
    return null;
  }

  // ─── Phone ───────────────────────────────────────────────────────────────

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  // ─── OTP ─────────────────────────────────────────────────────────────────

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be 6 digits.';
    }
    return null;
  }

  // ─── Credit Card (dummy validation) ──────────────────────────────────────

  static String? cardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required.';
    }
    final digits = value.replaceAll(' ', '');
    if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
      return 'Card number must be 16 digits.';
    }
    return null;
  }

  static String? cardExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required.';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value.trim())) {
      return 'Use MM/YY format.';
    }
    return null;
  }

  static String? cardCvv(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required.';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(value.trim())) {
      return 'CVV must be 3 or 4 digits.';
    }
    return null;
  }

  static String? cardholderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cardholder name is required.';
    }
    return null;
  }

  // ─── Required field ───────────────────────────────────────────────────────

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }
}

// ─── Password Rule Model ──────────────────────────────────────────────────────

/// Represents a single password requirement and whether it's met
class PasswordRule {
  final String label;
  final bool isPassed;

  const PasswordRule(this.label, this.isPassed);
}
