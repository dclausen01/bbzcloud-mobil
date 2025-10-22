/// BBZCloud Mobile - Todo Provider
/// 
/// State management for todos
/// 
/// @version 0.1.0

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/models/todo.dart';

const String _storageKey = 'bbzcloud_todos';

/// Todo State Notifier
class TodoNotifier extends StateNotifier<TodoState> {
  TodoNotifier() : super(TodoState.initial()) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final map = json.decode(jsonString) as Map<String, dynamic>;
        state = TodoState.fromMap(map);
        logger.info('Loaded ${state.todos.length} todos');
      }
    } catch (error, stackTrace) {
      logger.error('Error loading todos', error, stackTrace);
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.toMap());
      await prefs.setString(_storageKey, jsonString);
    } catch (error, stackTrace) {
      logger.error('Error saving todos', error, stackTrace);
    }
  }

  /// Add a new todo
  Future<void> addTodo(String text) async {
    if (text.trim().isEmpty) return;

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text.trim(),
      completed: false,
      createdAt: DateTime.now(),
      folder: state.selectedFolder,
    );

    state = state.copyWith(
      todos: [...state.todos, newTodo],
    );

    await _saveTodos();
    logger.info('Added todo: ${newTodo.text}');
  }

  /// Toggle todo completion
  Future<void> toggleTodo(int id) async {
    state = state.copyWith(
      todos: state.todos.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(completed: !todo.completed);
        }
        return todo;
      }).toList(),
    );

    await _saveTodos();
  }

  /// Update todo text
  Future<void> updateTodo(int id, String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      todos: state.todos.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(text: text.trim());
        }
        return todo;
      }).toList(),
    );

    await _saveTodos();
    logger.info('Updated todo $id');
  }

  /// Delete todo
  Future<void> deleteTodo(int id) async {
    state = state.copyWith(
      todos: state.todos.where((todo) => todo.id != id).toList(),
    );

    await _saveTodos();
    logger.info('Deleted todo $id');
  }

  /// Add a new folder
  Future<void> addFolder(String name) async {
    if (name.trim().isEmpty) return;

    final folderName = name.trim();

    if (state.folders.contains(folderName)) {
      logger.warning('Folder already exists: $folderName');
      return;
    }

    state = state.copyWith(
      folders: [...state.folders, folderName],
      selectedFolder: folderName,
    );

    await _saveTodos();
    logger.info('Added folder: $folderName');
  }

  /// Delete folder (moves todos to Standard)
  Future<void> deleteFolder(String folderName) async {
    if (folderName == 'Standard') {
      logger.warning('Cannot delete Standard folder');
      return;
    }

    // Move todos from deleted folder to Standard
    state = state.copyWith(
      todos: state.todos.map((todo) {
        if (todo.folder == folderName) {
          return todo.copyWith(folder: 'Standard');
        }
        return todo;
      }).toList(),
      folders: state.folders.where((f) => f != folderName).toList(),
      selectedFolder: state.selectedFolder == folderName
          ? 'Standard'
          : state.selectedFolder,
    );

    await _saveTodos();
    logger.info('Deleted folder: $folderName');
  }

  /// Change selected folder
  void selectFolder(String folderName) {
    if (state.folders.contains(folderName)) {
      state = state.copyWith(selectedFolder: folderName);
    }
  }
}

/// Provider for todo state
final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier();
});

/// Provider for filtered todos
final filteredTodosProvider = Provider.family<List<Todo>, TodoFilter>((ref, filter) {
  final todoState = ref.watch(todoProvider);
  
  return todoState.todos
      .where((todo) => todo.folder == todoState.selectedFolder)
      .where((todo) {
        switch (filter) {
          case TodoFilter.active:
            return !todo.completed;
          case TodoFilter.completed:
            return todo.completed;
          case TodoFilter.all:
            return true;
        }
      })
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Provider for active todo count in current folder
final activeTodoCountProvider = Provider<int>((ref) {
  final todoState = ref.watch(todoProvider);
  
  return todoState.todos
      .where((todo) =>
          todo.folder == todoState.selectedFolder && !todo.completed)
      .length;
});
