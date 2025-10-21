/// BBZCloud Mobile - Input Validators
/// 
/// Utility functions for input validation
/// 
/// @version 0.1.0

import 'package:bbzcloud_mobil/core/exceptions/app_exceptions.dart';

class Validators {
  Validators._();

  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // URL validation regex
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// Validate email address
  static void validateEmail(String? email, {bool required = true}) {
    if (email == null || email.isEmpty) {
      if (required) {
        throw ValidationException.requiredField('email');
      }
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      throw ValidationException.invalidEmail(email);
    }

    if (email.length > 255) {
      throw ValidationException.fieldTooLong('email', 255);
    }
  }

  /// Validate URL
  static void validateUrl(String? url, {bool required = true}) {
    if (url == null || url.isEmpty) {
      if (required) {
        throw ValidationException.requiredField('url');
      }
      return;
    }

    if (!_urlRegex.hasMatch(url)) {
      throw ValidationException.invalidUrl(url);
    }

    if (url.length > 2048) {
      throw ValidationException.fieldTooLong('url', 2048);
    }
  }

  /// Validate string field
  static void validateString(
    String? value,
    String fieldName, {
    bool required = true,
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.isEmpty) {
      if (required) {
        throw ValidationException.requiredField(fieldName);
      }
      return;
    }

    if (minLength != null && value.length < minLength) {
      throw ValidationException(
        'Feld "$fieldName" muss mindestens $minLength Zeichen lang sein',
        code: 'VALIDATION_FIELD_TOO_SHORT',
        fieldErrors: {fieldName: 'Mindestens $minLength Zeichen erforderlich'},
      );
    }

    if (maxLength != null && value.length > maxLength) {
      throw ValidationException.fieldTooLong(fieldName, maxLength);
    }
  }

  /// Validate integer field
  static void validateInt(
    int? value,
    String fieldName, {
    bool required = true,
    int? min,
    int? max,
  }) {
    if (value == null) {
      if (required) {
        throw ValidationException.requiredField(fieldName);
      }
      return;
    }

    if (min != null && value < min) {
      throw ValidationException(
        'Feld "$fieldName" muss mindestens $min sein',
        code: 'VALIDATION_VALUE_TOO_SMALL',
        fieldErrors: {fieldName: 'Mindestens $min erforderlich'},
      );
    }

    if (max != null && value > max) {
      throw ValidationException(
        'Feld "$fieldName" darf maximal $max sein',
        code: 'VALIDATION_VALUE_TOO_LARGE',
        fieldErrors: {fieldName: 'Maximal $max erlaubt'},
      );
    }
  }

  /// Validate that a string is not empty or just whitespace
  static void validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw ValidationException.requiredField(fieldName);
    }
  }

  /// Validate hex color code (e.g., #RRGGBB or #RGB)
  static void validateHexColor(String? color, {bool required = true}) {
    if (color == null || color.isEmpty) {
      if (required) {
        throw ValidationException.requiredField('color');
      }
      return;
    }

    final hexColorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    if (!hexColorRegex.hasMatch(color)) {
      throw ValidationException(
        'Ungültiger Farbcode: $color',
        code: 'VALIDATION_INVALID_COLOR',
        fieldErrors: {'color': 'Muss ein gültiger Hex-Farbcode sein (z.B. #FF5733)'},
      );
    }
  }

  /// Check if email is from BBZ domain
  static bool isBbzEmail(String email) {
    return email.toLowerCase().endsWith('@bbz-rd-eck.de');
  }

  /// Sanitize string by removing potentially dangerous characters
  static String sanitizeString(String input) {
    // Remove null bytes and control characters
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Validate and sanitize HTML/JavaScript input (basic XSS prevention)
  static String sanitizeHtml(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;');
  }
}
