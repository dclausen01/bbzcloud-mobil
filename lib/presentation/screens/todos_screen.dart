/// BBZCloud Mobile - Todos Screen
/// 
/// Todo list management screen
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/todo.dart';
import 'package:bbzcloud_mobil/presentation/providers/todo_provider.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  TodoFilter _currentFilter = TodoFilter.all;
  int? _editingTodoId;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoProvider);
    final filteredTodos = ref.watch(filteredTodosProvider(_currentFilter));
    final activeTodoCount = ref.watch(activeTodoCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufgaben'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => _showFolderDialog(context),
            tooltip: 'Ordner verwalten',
          ),
        ],
      ),
      body: Column(
        children: [
          // Folder Selector
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: DropdownButtonFormField<String>(
              value: todoState.selectedFolder,
              decoration: const InputDecoration(
                labelText: 'Ordner',
                prefixIcon: Icon(Icons.folder_open),
                border: OutlineInputBorder(),
              ),
              items: todoState.folders.map((folder) {
                return DropdownMenuItem(
                  value: folder,
                  child: Text(folder),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(todoProvider.notifier).selectFolder(value);
                }
              },
            ),
          ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<TodoFilter>(
              segments: [
                ButtonSegment(
                  value: TodoFilter.all,
                  label: Text(TodoFilter.all.displayName),
                ),
                ButtonSegment(
                  value: TodoFilter.active,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(TodoFilter.active.displayName),
                      if (activeTodoCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeTodoCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ButtonSegment(
                  value: TodoFilter.completed,
                  label: Text(TodoFilter.completed.displayName),
                ),
              ],
              selected: {_currentFilter},
              onSelectionChanged: (Set<TodoFilter> selected) {
                setState(() {
                  _currentFilter = selected.first;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Todo List
          Expanded(
            child: filteredTodos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Keine Aufgaben vorhanden',
                          style: AppTextStyles.body1.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = filteredTodos[index];
                      final isEditing = _editingTodoId == todo.id;

                      return Dismissible(
                        key: Key('todo_${todo.id}'),
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          ref.read(todoProvider.notifier).deleteTodo(todo.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aufgabe gelöscht'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: todo.completed,
                              onChanged: (_) {
                                ref.read(todoProvider.notifier).toggleTodo(todo.id);
                              },
                            ),
                            title: isEditing
                                ? TextField(
                                    controller: _editController,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Aufgabe eingeben...',
                                    ),
                                    onSubmitted: (value) {
                                      ref
                                          .read(todoProvider.notifier)
                                          .updateTodo(todo.id, value);
                                      setState(() {
                                        _editingTodoId = null;
                                      });
                                    },
                                  )
                                : Text(
                                    todo.text,
                                    style: todo.completed
                                        ? TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          )
                                        : null,
                                  ),
                            subtitle: Text(
                              DateFormat('dd.MM.yyyy').format(todo.createdAt),
                              style: AppTextStyles.caption,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _editingTodoId = todo.id;
                                      _editController.text = todo.text;
                                    });
                                  },
                                  tooltip: 'Bearbeiten',
                                ),
                                Icon(
                                  todo.completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: todo.completed
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Aufgabe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Aufgabe eingeben...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(todoProvider.notifier).addTodo(value);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aufgabe hinzugefügt'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(todoProvider.notifier).addTodo(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aufgabe hinzugefügt'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _showFolderDialog(BuildContext context) {
    final todoState = ref.read(todoProvider);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordner verwalten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Neuer Ordnername',
                hintText: 'Ordner eingeben...',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),
            if (todoState.selectedFolder != 'Standard')
              FilledButton.tonal(
                onPressed: () {
                  ref
                      .read(todoProvider.notifier)
                      .deleteFolder(todoState.selectedFolder);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ordner gelöscht'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                ),
                child: const Text('Aktuellen Ordner löschen'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(todoProvider.notifier).addFolder(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ordner erstellt'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }
}
