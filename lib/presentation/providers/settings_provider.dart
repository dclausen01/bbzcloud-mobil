/// BBZCloud Mobile - Settings Provider
/// 
/// State management for app settings
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/data/services/database_service.dart';

/// Settings state
class SettingsState {
  final AppThemeMode theme;
  final bool isFirstLaunch;

  const SettingsState({
    required this.theme,
    required this.isFirstLaunch,
  });

  SettingsState copyWith({
    AppThemeMode? theme,
    bool? isFirstLaunch,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
    );
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsState>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsState>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  final _database = DatabaseService.instance;

  /// Load settings from database
  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    
    try {
      final settings = await _database.getAllSettings();
      
      final themeValue = settings[StorageKeys.theme] ?? AppThemeMode.system.value;
      final isFirstLaunch = settings[StorageKeys.isFirstLaunch] != 'false';
      
      state = AsyncValue.data(SettingsState(
        theme: AppThemeMode.fromString(themeValue),
        isFirstLaunch: isFirstLaunch,
      ));
    } catch (error, stackTrace) {
      // If error, provide defaults
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Set theme
  Future<void> setTheme(AppThemeMode theme) async {
    try {
      await _database.saveSetting(StorageKeys.theme, theme.value);
      
      state.whenData((currentState) {
        state = AsyncValue.data(currentState.copyWith(theme: theme));
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark first launch as complete
  Future<void> completeFirstLaunch() async {
    try {
      await _database.saveSetting(StorageKeys.isFirstLaunch, 'false');
      
      state.whenData((currentState) {
        state = AsyncValue.data(currentState.copyWith(isFirstLaunch: false));
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reload settings
  Future<void> reload() async {
    await _loadSettings();
  }
}

/// Helper provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsState = ref.watch(settingsProvider);
  
  return settingsState.maybeWhen(
    data: (settings) {
      switch (settings.theme) {
        case AppThemeMode.light:
          return ThemeMode.light;
        case AppThemeMode.dark:
          return ThemeMode.dark;
        case AppThemeMode.system:
          return ThemeMode.system;
      }
    },
    orElse: () => ThemeMode.system,
  );
});

/// Helper provider to check if first launch
final isFirstLaunchProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsProvider);
  
  return settingsState.maybeWhen(
    data: (settings) => settings.isFirstLaunch,
    orElse: () => true,
  );
});
