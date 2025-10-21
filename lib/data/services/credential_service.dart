/// BBZCloud Mobile - Credential Service
/// 
/// Secure credential storage using flutter_secure_storage
/// 
/// @version 0.1.0

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/data/models/credentials.dart';

class CredentialService {
  static final CredentialService instance = CredentialService._internal();
  
  CredentialService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ============================================================================
  // SAVE OPERATIONS
  // ============================================================================

  /// Save all credentials
  Future<void> saveCredentials(Credentials credentials) async {
    if (credentials.email != null) {
      await _storage.write(
        key: StorageKeys.credentialEmail,
        value: credentials.email,
      );
    }

    if (credentials.password != null) {
      await _storage.write(
        key: StorageKeys.credentialPassword,
        value: credentials.password,
      );
    }

    if (credentials.bbbPassword != null) {
      await _storage.write(
        key: StorageKeys.credentialBbbPassword,
        value: credentials.bbbPassword,
      );
    }

    if (credentials.webuntisEmail != null) {
      await _storage.write(
        key: StorageKeys.credentialWebuntisEmail,
        value: credentials.webuntisEmail,
      );
    }

    if (credentials.webuntisPassword != null) {
      await _storage.write(
        key: StorageKeys.credentialWebuntisPassword,
        value: credentials.webuntisPassword,
      );
    }
  }

  /// Save email only
  Future<void> saveEmail(String email) async {
    await _storage.write(
      key: StorageKeys.credentialEmail,
      value: email,
    );
  }

  /// Save password only
  Future<void> savePassword(String password) async {
    await _storage.write(
      key: StorageKeys.credentialPassword,
      value: password,
    );
  }

  /// Save BBB password
  Future<void> saveBbbPassword(String password) async {
    await _storage.write(
      key: StorageKeys.credentialBbbPassword,
      value: password,
    );
  }

  /// Save WebUntis credentials
  Future<void> saveWebuntisCredentials({
    String? email,
    String? password,
  }) async {
    if (email != null) {
      await _storage.write(
        key: StorageKeys.credentialWebuntisEmail,
        value: email,
      );
    }

    if (password != null) {
      await _storage.write(
        key: StorageKeys.credentialWebuntisPassword,
        value: password,
      );
    }
  }

  // ============================================================================
  // LOAD OPERATIONS
  // ============================================================================

  /// Load all credentials
  Future<Credentials> loadCredentials() async {
    final email = await _storage.read(key: StorageKeys.credentialEmail);
    final password = await _storage.read(key: StorageKeys.credentialPassword);
    final bbbPassword = await _storage.read(
      key: StorageKeys.credentialBbbPassword,
    );
    final webuntisEmail = await _storage.read(
      key: StorageKeys.credentialWebuntisEmail,
    );
    final webuntisPassword = await _storage.read(
      key: StorageKeys.credentialWebuntisPassword,
    );

    return Credentials(
      email: email,
      password: password,
      bbbPassword: bbbPassword,
      webuntisEmail: webuntisEmail,
      webuntisPassword: webuntisPassword,
    );
  }

  /// Load email only
  Future<String?> loadEmail() async {
    return await _storage.read(key: StorageKeys.credentialEmail);
  }

  /// Load password only
  Future<String?> loadPassword() async {
    return await _storage.read(key: StorageKeys.credentialPassword);
  }

  /// Load BBB password
  Future<String?> loadBbbPassword() async {
    return await _storage.read(key: StorageKeys.credentialBbbPassword);
  }

  /// Load WebUntis email
  Future<String?> loadWebuntisEmail() async {
    return await _storage.read(key: StorageKeys.credentialWebuntisEmail);
  }

  /// Load WebUntis password
  Future<String?> loadWebuntisPassword() async {
    return await _storage.read(key: StorageKeys.credentialWebuntisPassword);
  }

  // ============================================================================
  // DELETE OPERATIONS
  // ============================================================================

  /// Delete specific credential
  Future<void> deleteCredential(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all credentials
  Future<void> deleteAllCredentials() async {
    await _storage.delete(key: StorageKeys.credentialEmail);
    await _storage.delete(key: StorageKeys.credentialPassword);
    await _storage.delete(key: StorageKeys.credentialBbbPassword);
    await _storage.delete(key: StorageKeys.credentialWebuntisEmail);
    await _storage.delete(key: StorageKeys.credentialWebuntisPassword);
  }

  /// Clear all secure storage (dangerous!)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================

  /// Check if credentials exist
  Future<bool> hasCredentials() async {
    final email = await loadEmail();
    return email != null && email.isNotEmpty;
  }

  /// Check if specific credential exists
  Future<bool> hasCredential(String key) async {
    final value = await _storage.read(key: key);
    return value != null && value.isNotEmpty;
  }

  /// Get all keys (for debugging)
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
