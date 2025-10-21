/// BBZCloud Mobile - User Provider Tests
/// 
/// Unit tests for UserProvider
/// 
/// @version 0.1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/data/models/user.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';

// Note: Tests simplified for basic functionality check

void main() {
  group('UserProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is loading', () {
      final state = container.read(userProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('isLoggedInProvider returns false when no user', () {
      final isLoggedIn = container.read(isLoggedInProvider);
      expect(isLoggedIn, false);
    });

    test('saveUser updates state correctly', () async {
      final notifier = container.read(userProvider.notifier);
      
      final testUser = User(
        email: 'test@bbz-rd-eck.de',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.saveUser(testUser);
      
      final state = container.read(userProvider);
      expect(state.hasValue, true);
      expect(state.value?.email, 'test@bbz-rd-eck.de');
      expect(state.value?.role, UserRole.teacher);
    });

    test('isTeacherProvider returns true for teacher', () async {
      final notifier = container.read(userProvider.notifier);
      
      final teacherUser = User(
        email: 'teacher@bbz-rd-eck.de',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.saveUser(teacherUser);
      
      final isTeacher = container.read(isTeacherProvider);
      expect(isTeacher, true);
    });

    test('isTeacherProvider returns false for student', () async {
      final notifier = container.read(userProvider.notifier);
      
      final studentUser = User(
        email: 'student@example.com',
        role: UserRole.student,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.saveUser(studentUser);
      
      final isTeacher = container.read(isTeacherProvider);
      expect(isTeacher, false);
    });

    test('clearUser sets state to null', () async {
      final notifier = container.read(userProvider.notifier);
      
      // First save a user
      final testUser = User(
        email: 'test@example.com',
        role: UserRole.student,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await notifier.saveUser(testUser);
      
      // Then clear
      notifier.clearUser();
      
      final state = container.read(userProvider);
      expect(state.hasValue, true);
      expect(state.value, null);
    });
  });
}
