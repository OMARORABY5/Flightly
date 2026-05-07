// validators_test.dart — FLIGHTLY Flutter Validator Unit Tests
// Tests for all input validation functions in validators.dart.
// WHY: Validators are called on every form submission across the app.
//      A bug here would silently let invalid data through to the server.

import 'package:flutter_test/flutter_test.dart';
import 'package:flightly/core/utils/validators.dart';

void main() {
  // ─── Email Validator Tests ───────────────────────────────────────────────────
  group('Validators.email', () {
    test('should return error for empty email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(''), contains('required'));
    });

    test('should return error for null email', () {
      expect(Validators.email(null), isNotNull);
    });

    test('should return error for whitespace-only email', () {
      expect(Validators.email('   '), isNotNull);
    });

    test('should return error for email without @ symbol', () {
      expect(Validators.email('notanemail.com'), isNotNull);
    });

    test('should return error for email without domain', () {
      expect(Validators.email('user@'), isNotNull);
    });

    test('should return error for email without TLD', () {
      expect(Validators.email('user@domain'), isNotNull);
    });

    test('should return null (valid) for a correct email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('should return null (valid) for email with subdomain', () {
      expect(Validators.email('user@mail.example.co.uk'), isNull);
    });

    test('should return null (valid) for email with plus sign', () {
      expect(Validators.email('user+tag@example.com'), isNull);
    });
  });

  // ─── Password Validator Tests ────────────────────────────────────────────────
  group('Validators.password', () {
    test('should return error for empty password', () {
      expect(Validators.password(''), isNotNull);
    });

    test('should return error for null password', () {
      expect(Validators.password(null), isNotNull);
    });

    test('should return error for password shorter than 8 characters', () {
      final result = Validators.password('abc12');
      expect(result, isNotNull);
      expect(result, contains('8 characters'));
    });

    test('should return error for password with exactly 7 characters', () {
      expect(Validators.password('Abc123!'), isNotNull);
    });

    test('should return null (valid) for password with exactly 8 characters', () {
      expect(Validators.password('Abcd1234'), isNull);
    });

    test('should return null (valid) for a strong password', () {
      expect(Validators.password('MyStr0ng!Pass'), isNull);
    });
  });

  // ─── Confirm Password Validator Tests ────────────────────────────────────────
  group('Validators.confirmPassword', () {
    test('should return error when confirm password is empty', () {
      expect(Validators.confirmPassword('', 'Test1234!'), isNotNull);
    });

    test('should return error when passwords do not match', () {
      final result = Validators.confirmPassword('Different!', 'Test1234!');
      expect(result, isNotNull);
      expect(result, contains('match'));
    });

    test('should return null when passwords match exactly', () {
      expect(Validators.confirmPassword('Test1234!', 'Test1234!'), isNull);
    });
  });

  // ─── Passport Validator Tests ─────────────────────────────────────────────────
  group('Validators.passportNumber', () {
    test('should return error for empty passport', () {
      expect(Validators.passportNumber(''), isNotNull);
    });

    test('should return error for passport that is too short (< 6 chars)', () {
      expect(Validators.passportNumber('AB123'), isNotNull);
    });

    test('should return error for passport that is too long (> 12 chars)', () {
      expect(Validators.passportNumber('AB1234567890123'), isNotNull);
    });

    test('should return error for passport with special characters', () {
      expect(Validators.passportNumber('AB-123456'), isNotNull);
    });

    test('should return null (valid) for a proper 9-character passport', () {
      expect(Validators.passportNumber('AB1234567'), isNull);
    });

    test('should return null (valid) for lowercase input (normalized internally)', () {
      expect(Validators.passportNumber('ab1234567'), isNull);
    });
  });

  // ─── Password Rules Tests ─────────────────────────────────────────────────────
  group('Validators.passwordRules', () {
    test('should return 5 rules total', () {
      final rules = Validators.passwordRules('SomePass1!');
      expect(rules.length, equals(5));
    });

    test('should mark all rules as passing for a strong password', () {
      final rules = Validators.passwordRules('StrongP@ss1');
      expect(rules.every((r) => r.isPassed), isTrue);
    });

    test('should fail length rule for short password', () {
      final rules = Validators.passwordRules('Ab1!');
      final lengthRule = rules.firstWhere((r) => r.label.contains('8'));
      expect(lengthRule.isPassed, isFalse);
    });

    test('should fail uppercase rule for all-lowercase password', () {
      final rules = Validators.passwordRules('abcd1234!');
      final uppercaseRule = rules.firstWhere((r) => r.label.contains('uppercase'));
      expect(uppercaseRule.isPassed, isFalse);
    });

    test('should fail number rule for password without digits', () {
      final rules = Validators.passwordRules('StrongPass!');
      final numberRule = rules.firstWhere((r) => r.label.contains('number'));
      expect(numberRule.isPassed, isFalse);
    });
  });

  // ─── OTP Validator Tests ──────────────────────────────────────────────────────
  group('Validators.otp', () {
    test('should return error for empty OTP', () {
      expect(Validators.otp(''), isNotNull);
    });

    test('should return error for OTP with fewer than 6 digits', () {
      expect(Validators.otp('12345'), isNotNull);
    });

    test('should return error for OTP with letters', () {
      expect(Validators.otp('12345a'), isNotNull);
    });

    test('should return null for a valid 6-digit OTP', () {
      expect(Validators.otp('123456'), isNull);
    });
  });
}
