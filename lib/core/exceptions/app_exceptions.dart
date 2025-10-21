/// BBZCloud Mobile - Custom Exceptions
/// 
/// Defines custom exception classes for better error handling
/// 
/// @version 0.1.0

/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseException.connection(String details) {
    return DatabaseException(
      'Datenbankverbindung fehlgeschlagen: $details',
      code: 'DB_CONNECTION_ERROR',
    );
  }

  factory DatabaseException.transaction(String details) {
    return DatabaseException(
      'Transaktion fehlgeschlagen: $details',
      code: 'DB_TRANSACTION_ERROR',
    );
  }

  factory DatabaseException.query(String details) {
    return DatabaseException(
      'Abfrage fehlgeschlagen: $details',
      code: 'DB_QUERY_ERROR',
    );
  }
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthenticationException.invalidCredentials() {
    return const AuthenticationException(
      'Ungültige Anmeldedaten',
      code: 'AUTH_INVALID_CREDENTIALS',
    );
  }

  factory AuthenticationException.sessionExpired() {
    return const AuthenticationException(
      'Sitzung abgelaufen. Bitte melden Sie sich erneut an.',
      code: 'AUTH_SESSION_EXPIRED',
    );
  }

  factory AuthenticationException.unauthorized() {
    return const AuthenticationException(
      'Keine Berechtigung für diese Aktion',
      code: 'AUTH_UNAUTHORIZED',
    );
  }
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    super.code,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.invalidEmail(String email) {
    return ValidationException(
      'Ungültige E-Mail-Adresse: $email',
      code: 'VALIDATION_INVALID_EMAIL',
      fieldErrors: {'email': 'Ungültige E-Mail-Adresse'},
    );
  }

  factory ValidationException.invalidUrl(String url) {
    return ValidationException(
      'Ungültige URL: $url',
      code: 'VALIDATION_INVALID_URL',
      fieldErrors: {'url': 'Ungültige URL'},
    );
  }

  factory ValidationException.requiredField(String fieldName) {
    return ValidationException(
      'Pflichtfeld fehlt: $fieldName',
      code: 'VALIDATION_REQUIRED_FIELD',
      fieldErrors: {fieldName: 'Dieses Feld ist erforderlich'},
    );
  }

  factory ValidationException.fieldTooLong(String fieldName, int maxLength) {
    return ValidationException(
      'Feld "$fieldName" ist zu lang (max. $maxLength Zeichen)',
      code: 'VALIDATION_FIELD_TOO_LONG',
      fieldErrors: {fieldName: 'Maximal $maxLength Zeichen erlaubt'},
    );
  }
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.readError(String key) {
    return StorageException(
      'Fehler beim Lesen von Speicher-Key: $key',
      code: 'STORAGE_READ_ERROR',
    );
  }

  factory StorageException.writeError(String key) {
    return StorageException(
      'Fehler beim Schreiben von Speicher-Key: $key',
      code: 'STORAGE_WRITE_ERROR',
    );
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      'Keine Internetverbindung',
      code: 'NETWORK_NO_CONNECTION',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      'Zeitüberschreitung bei Netzwerkanfrage',
      code: 'NETWORK_TIMEOUT',
    );
  }

  factory NetworkException.serverError(int statusCode) {
    return NetworkException(
      'Serverfehler (Status: $statusCode)',
      code: 'NETWORK_SERVER_ERROR',
    );
  }
}
