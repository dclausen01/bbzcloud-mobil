/// BBZCloud Mobile - Apps Provider
/// 
/// State management for navigation and custom apps
/// 
/// @version 0.1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/data/models/user.dart';
import 'package:bbzcloud_mobil/data/services/database_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';

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

  /// Add custom app
  Future<void> addApp(CustomApp app) async {
    try {
      await _database.saveCustomApp(app);
      await reload();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update custom app
  Future<void> updateApp(CustomApp app) async {
    try {
      await _database.updateCustomApp(app);
      await reload();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete custom app
  Future<void> deleteApp(String appId) async {
    try {
      await _database.deleteCustomApp(appId);
      await reload();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
      return allApps.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
    },
    orElse: () => [],
  );
});

/// All apps (navigation + custom) combined
final allAppsProvider = Provider<List<dynamic>>((ref) {
  final navigationApps = ref.watch(filteredNavigationAppsProvider);
  final customAppsState = ref.watch(customAppsProvider);
  
  return customAppsState.maybeWhen(
    data: (customApps) {
      return [...navigationApps, ...customApps];
    },
    orElse: () => navigationApps,
  );
});

/// Count of available apps
final appsCountProvider = Provider<int>((ref) {
  final apps = ref.watch(allAppsProvider);
  return apps.length;
});
