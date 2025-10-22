/// BBZCloud Mobile - Todo Model
/// 
/// @version 0.1.0

class Todo {
  final int id;
  final String text;
  final bool completed;
  final DateTime createdAt;
  final String folder;

  const Todo({
    required this.id,
    required this.text,
    required this.completed,
    required this.createdAt,
    required this.folder,
  });

  /// Create Todo from database map
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int,
      text: map['text'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      folder: map['folder'] as String? ?? 'Standard',
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
    };
  }

  /// Create a copy with updated fields
  Todo copyWith({
    int? id,
    String? text,
    bool? completed,
    DateTime? createdAt,
    String? folder,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      folder: folder ?? this.folder,
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

  const TodoState({
    required this.todos,
    required this.folders,
    required this.selectedFolder,
  });

  factory TodoState.initial() {
    return const TodoState(
      todos: [],
      folders: ['Standard'],
      selectedFolder: 'Standard',
    );
  }

  factory TodoState.fromMap(Map<String, dynamic> map) {
    return TodoState(
      todos: (map['todos'] as List<dynamic>?)
              ?.map((e) => Todo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      folders: (map['folders'] as List<dynamic>?)?.cast<String>() ?? ['Standard'],
      selectedFolder: map['selectedFolder'] as String? ?? 'Standard',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'todos': todos.map((e) => e.toMap()).toList(),
      'folders': folders,
      'selectedFolder': selectedFolder,
    };
  }

  TodoState copyWith({
    List<Todo>? todos,
    List<String>? folders,
    String? selectedFolder,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      folders: folders ?? this.folders,
      selectedFolder: selectedFolder ?? this.selectedFolder,
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
