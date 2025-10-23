/// BBZCloud Mobile - Apps Provider
/// 
/// State management for navigation and custom apps
/// 
/// @version 0.1.0

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/data/models/user.dart';
import 'package:bbzcloud_mobil/data/services/database_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';

const String _appSettingsKey = 'bbzcloud_app_settings';

/// App settings (visibility and order)
class AppSettings {
  final Map<String, bool> visibility;
  final Map<String, int> order;

  const AppSettings({
    required this.visibility,
    required this.order,
  });

  factory AppSettings.empty() {
    return const AppSettings(visibility: {}, order: {});
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      visibility: Map<String, bool>.from(json['visibility'] ?? {}),
      order: Map<String, int>.from(json['order'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visibility': visibility,
      'order': order,
    };
  }

  bool isVisible(String appId) => visibility[appId] ?? true;
  int getOrder(String appId) => order[appId] ?? 999;
}

/// App settings provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings.empty()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_appSettingsKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
        logger.info('Loaded app settings');
      }
    } catch (error, stackTrace) {
      logger.error('Error loading app settings', error, stackTrace);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_appSettingsKey, jsonString);
    } catch (error, stackTrace) {
      logger.error('Error saving app settings', error, stackTrace);
    }
  }

  /// Toggle app visibility
  Future<void> toggleVisibility(String appId) async {
    final newVisibility = Map<String, bool>.from(state.visibility);
    newVisibility[appId] = !(state.visibility[appId] ?? true);
    
    state = AppSettings(
      visibility: newVisibility,
      order: state.order,
    );
    
    await _saveSettings();
    logger.info('Toggled visibility for $appId: ${newVisibility[appId]}');
  }

  /// Reorder apps
  Future<void> reorderApps(List<String> appIds) async {
    final newOrder = <String, int>{};
    
    for (int i = 0; i < appIds.length; i++) {
      newOrder[appIds[i]] = i;
    }
    
    state = AppSettings(
      visibility: state.visibility,
      order: newOrder,
    );
    
    await _saveSettings();
    logger.info('Reordered ${appIds.length} apps');
  }
}

/// Custom apps provider
final customAppsProvider = StateNotifierProvider<CustomAppsNotifier, AsyncValue<List<CustomApp>>>((ref) {
  final notifier = CustomAppsNotifier(ref);
  
  // Watch for user changes and reload apps
  ref.listen<AsyncValue<User?>>(
    userProvider,
    (previous, next) {
      next.whenData((user) {
        if (previous?.value?.id != user?.id) {
          notifier.reload();
        }
      });
    },
  );
  
  return notifier;
});

class CustomAppsNotifier extends StateNotifier<AsyncValue<List<CustomApp>>> {
  CustomAppsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadCustomApps();
  }

  final Ref ref;
  final _database = DatabaseService.instance;

  /// Load custom apps from database
  Future<void> _loadCustomApps() async {
    state = const AsyncValue.loading();
    
    try {
      final userState = ref.read(userProvider);
      final userId = userState.value?.id;
      
      final apps = await _database.getCustomApps(userId);
      state = AsyncValue.data(apps);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add custom app with optimistic update
  Future<void> addApp(CustomApp app) async {
    // Save previous state for rollback
    final previousState = state;
    
    try {
      // Optimistic update: Add to state immediately
      state.whenData((apps) {
        state = AsyncValue.data([...apps, app]);
      });
      
      // Persist to database
      await _database.saveCustomApp(app);
      
      // Verify by reloading (but don't fail if reload has issues)
      try {
        await reload();
      } catch (reloadError) {
        logger.warning('Reload after add failed, but app was saved', reloadError);
        // Keep optimistic state since save succeeded
      }
    } catch (error, stackTrace) {
      // Rollback to previous state on failure
      state = previousState;
      logger.error('Failed to add custom app', error, stackTrace);
      rethrow;
    }
  }

  /// Update custom app with optimistic update
  Future<void> updateApp(CustomApp app) async {
    // Save previous state for rollback
    final previousState = state;
    
    try {
      // Optimistic update: Replace in state immediately
      state.whenData((apps) {
        final updatedApps = apps.map((a) => a.id == app.id ? app : a).toList();
        state = AsyncValue.data(updatedApps);
      });
      
      // Persist to database
      await _database.updateCustomApp(app);
      
      // Verify by reloading (but don't fail if reload has issues)
      try {
        await reload();
      } catch (reloadError) {
        logger.warning('Reload after update failed, but app was updated', reloadError);
        // Keep optimistic state since update succeeded
      }
    } catch (error, stackTrace) {
      // Rollback to previous state on failure
      state = previousState;
      logger.error('Failed to update custom app', error, stackTrace);
      rethrow;
    }
  }

  /// Delete custom app with optimistic update
  Future<void> deleteApp(String appId) async {
    // Save previous state for rollback
    final previousState = state;
    
    try {
      // Optimistic update: Remove from state immediately
      state.whenData((apps) {
        final filteredApps = apps.where((a) => a.id != appId).toList();
        state = AsyncValue.data(filteredApps);
      });
      
      // Persist to database
      await _database.deleteCustomApp(appId);
      
      // Verify by reloading (but don't fail if reload has issues)
      try {
        await reload();
      } catch (reloadError) {
        logger.warning('Reload after delete failed, but app was deleted', reloadError);
        // Keep optimistic state since delete succeeded
      }
    } catch (error, stackTrace) {
      // Rollback to previous state on failure
      state = previousState;
      logger.error('Failed to delete custom app', error, stackTrace);
      rethrow;
    }
  }

  /// Reload custom apps
  Future<void> reload() async {
    await _loadCustomApps();
  }
}

/// Navigation apps filtered by user role
final filteredNavigationAppsProvider = Provider<List<AppItem>>((ref) {
  final userState = ref.watch(userProvider);
  
  return userState.maybeWhen(
    data: (user) {
      if (user == null) {
        return [];
      }
      
      final allApps = NavigationApps.getAppsForRole(user.role.value);
      return allApps.values.toList();
    },
    orElse: () => [],
  );
});

/// All apps (navigation + custom) combined and sorted
final allAppsProvider = Provider<List<dynamic>>((ref) {
  final navigationApps = ref.watch(filteredNavigationAppsProvider);
  final customAppsState = ref.watch(customAppsProvider);
  final settings = ref.watch(appSettingsProvider);
  
  final customApps = customAppsState.maybeWhen(
    data: (apps) => apps,
    orElse: () => <CustomApp>[],
  );
  
  // Combine all apps
  final allApps = <dynamic>[...navigationApps, ...customApps];
  
  // Sort by order
  allApps.sort((a, b) {
    final aId = a is AppItem ? a.id : (a as CustomApp).id;
    final bId = b is AppItem ? b.id : (b as CustomApp).id;
    
    final aOrder = settings.getOrder(aId);
    final bOrder = settings.getOrder(bId);
    
    if (aOrder != bOrder) {
      return aOrder.compareTo(bOrder);
    }
    
    // If same order, sort by title
    final aTitle = a is AppItem ? a.title : (a as CustomApp).title;
    final bTitle = b is AppItem ? b.title : (b as CustomApp).title;
    return aTitle.compareTo(bTitle);
  });
  
  return allApps;
});

/// Visible apps only (for normal mode)
final visibleAppsProvider = Provider<List<dynamic>>((ref) {
  final allApps = ref.watch(allAppsProvider);
  final settings = ref.watch(appSettingsProvider);
  
  return allApps.where((app) {
    final appId = app is AppItem ? app.id : (app as CustomApp).id;
    return settings.isVisible(appId);
  }).toList();
});

/// Count of available apps
final appsCountProvider = Provider<int>((ref) {
  final apps = ref.watch(visibleAppsProvider);
  return apps.length;
});
