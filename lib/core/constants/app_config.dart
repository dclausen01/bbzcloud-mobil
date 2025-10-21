/// BBZCloud Mobile - Application Configuration
/// 
/// This file contains all the configuration constants for the mobile application.
/// Adapted from the Ionic version for Flutter.
/// 
/// @version 0.1.0

class AppConfig {
  AppConfig._();

  static const String appName = 'BBZCloud Mobile';
  static const String appVersion = '0.1.0';
  static const String storagePrefix = 'bbzcloud_';
  static const String databaseName = 'bbzcloud.db';
  static const int databaseVersion = 1;

  // UI Configuration
  static const int toastDuration = 3000; // milliseconds
  static const int loadingTimeout = 30000; // milliseconds
  static const bool hapticFeedback = true;
  static const int animationDuration = 300; // milliseconds

  // Browser Configuration
  static const String toolbarColor = '#3880ff';
  static const bool showTitle = true;
  static const bool enableShare = true;
  static const bool enableReaderMode = false;
}

/// User Roles
enum UserRole {
  student('student', 'Schüler/in'),
  teacher('teacher', 'Lehrkraft'),
  admin('admin', 'Administrator');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.student,
    );
  }
}

/// Theme Modes
enum AppThemeMode {
  light('light', 'Hell'),
  dark('dark', 'Dunkel'),
  system('system', 'System');

  const AppThemeMode(this.value, this.displayName);

  final String value;
  final String displayName;

  static AppThemeMode fromString(String value) {
    return AppThemeMode.values.firstWhere(
      (theme) => theme.value == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
