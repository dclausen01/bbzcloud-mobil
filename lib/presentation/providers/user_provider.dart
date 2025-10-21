/// BBZCloud Mobile - User Provider
/// 
/// State management for current user
/// 
/// @version 0.1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/models/user.dart';
import 'package:bbzcloud_mobil/data/services/database_service.dart';

/// Current user state provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final _database = DatabaseService.instance;

  /// Load current user from database
  Future<void> _loadUser() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _database.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Save or update user
  Future<void> saveUser(User user) async {
    state = const AsyncValue.loading();
    try {
      await _database.saveUser(user);
      // Reload from database to ensure consistency
      await _loadUser();
      logger.info('User saved and reloaded successfully');
    } catch (error, stackTrace) {
      logger.error('Failed to save user', error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reload user from database
  Future<void> reload() async {
    await _loadUser();
  }

  /// Clear user (logout)
  void clearUser() {
    state = const AsyncValue.data(null);
  }
}

/// Helper provider to check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Helper provider to check if user is teacher
final isTeacherProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (user) => user?.isTeacher ?? false,
    orElse: () => false,
  );
});
