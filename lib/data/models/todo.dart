/// BBZCloud Mobile - Todo Model
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';

/// Priority levels for todos
enum TodoPriority {
  urgent(1, 'Dringend', Color(0xFFE53935)),      // Red
  high(2, 'Hoch', Color(0xFFFF6F00)),           // Orange
  normal(3, 'Normal', Color(0xFFFDD835)),       // Yellow
  low(4, 'Niedrig', Color(0xFF43A047));         // Green

  final int level;
  final String displayName;
  final Color color;

  const TodoPriority(this.level, this.displayName, this.color);

  static TodoPriority fromLevel(int level) {
    return TodoPriority.values.firstWhere(
      (p) => p.level == level,
      orElse: () => TodoPriority.normal,
    );
  }
}

/// Sort order for todos
enum TodoSortOrder {
  priority('Nach Priorität'),
  createdDate('Nach Erstellungsdatum'),
  manual('Manuelle Sortierung');

  final String displayName;
  const TodoSortOrder(this.displayName);
}

class Todo {
  final int id;
  final String text;
  final bool completed;
  final DateTime createdAt;
  final String folder;
  final TodoPriority priority;
  final int sortOrder;

  const Todo({
    required this.id,
    required this.text,
    required this.completed,
    required this.createdAt,
    required this.folder,
    this.priority = TodoPriority.normal,
    this.sortOrder = 0,
  });

  /// Create Todo from database map
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int,
      text: map['text'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      folder: map['folder'] as String? ?? 'Standard',
      priority: TodoPriority.fromLevel(map['priority'] as int? ?? 3),
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  /// Convert Todo to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'folder': folder,
      'priority': priority.level,
      'sort_order': sortOrder,
    };
  }

  /// Create a copy with updated fields
  Todo copyWith({
    int? id,
    String? text,
    bool? completed,
    DateTime? createdAt,
    String? folder,
    TodoPriority? priority,
    int? sortOrder,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      folder: folder ?? this.folder,
      priority: priority ?? this.priority,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TodoState {
  final List<Todo> todos;
  final List<String> folders;
  final String selectedFolder;
  final TodoSortOrder sortOrder;

  const TodoState({
    required this.todos,
    required this.folders,
    required this.selectedFolder,
    this.sortOrder = TodoSortOrder.priority,
  });

  factory TodoState.initial() {
    return const TodoState(
      todos: [],
      folders: ['Standard'],
      selectedFolder: 'Standard',
      sortOrder: TodoSortOrder.priority,
    );
  }

  factory TodoState.fromMap(Map<String, dynamic> map) {
    TodoSortOrder sortOrder = TodoSortOrder.priority;
    if (map['sortOrder'] != null) {
      final sortOrderIndex = map['sortOrder'] as int;
      if (sortOrderIndex < TodoSortOrder.values.length) {
        sortOrder = TodoSortOrder.values[sortOrderIndex];
      }
    }

    return TodoState(
      todos: (map['todos'] as List<dynamic>?)
              ?.map((e) => Todo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      folders: (map['folders'] as List<dynamic>?)?.cast<String>() ?? ['Standard'],
      selectedFolder: map['selectedFolder'] as String? ?? 'Standard',
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'todos': todos.map((e) => e.toMap()).toList(),
      'folders': folders,
      'selectedFolder': selectedFolder,
      'sortOrder': sortOrder.index,
    };
  }

  TodoState copyWith({
    List<Todo>? todos,
    List<String>? folders,
    String? selectedFolder,
    TodoSortOrder? sortOrder,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      folders: folders ?? this.folders,
      selectedFolder: selectedFolder ?? this.selectedFolder,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum TodoFilter {
  all,
  active,
  completed;

  String get displayName {
    switch (this) {
      case TodoFilter.all:
        return 'Alle';
      case TodoFilter.active:
        return 'Offen';
      case TodoFilter.completed:
        return 'Erledigt';
    }
  }
}
