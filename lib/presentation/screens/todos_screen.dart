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
            icon: const Icon(Icons.create_new_folder),
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

          // Sort Order Dropdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: DropdownButtonFormField<TodoSortOrder>(
              value: todoState.sortOrder,
              decoration: const InputDecoration(
                labelText: 'Sortierung',
                prefixIcon: Icon(Icons.sort),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              items: TodoSortOrder.values.map((sortOrder) {
                return DropdownMenuItem(
                  value: sortOrder,
                  child: Text(sortOrder.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(todoProvider.notifier).setSortOrder(value);
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
                : todoState.sortOrder == TodoSortOrder.manual
                    ? ReorderableListView.builder(
                        itemCount: filteredTodos.length,
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final reordered = List<Todo>.from(filteredTodos);
                          final todo = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, todo);
                          ref.read(todoProvider.notifier).reorderTodos(reordered);
                        },
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
                            child: _buildTodoCard(todo, isEditing),
                          );
                        },
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
                            child: _buildTodoCard(todo, isEditing),
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

  Widget _buildTodoCard(Todo todo, bool isEditing) {
    // Determine border color based on due date status
    Color borderColor = todo.effectivePriority.color.withOpacity(0.5);
    if (todo.isOverdue) {
      borderColor = Colors.red;
    } else if (todo.isDueToday) {
      borderColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 3,
        ),
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
                  ref.read(todoProvider.notifier).updateTodo(todo.id, value);
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: todo.priority.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: todo.priority.color,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    todo.priority.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: todo.priority.color,
                    ),
                  ),
                ),
                // Created Date
                Text(
                  DateFormat('dd.MM.yyyy').format(todo.createdAt),
                  style: AppTextStyles.caption,
                ),
                // Due Date Badge
                if (todo.dueDate != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: todo.isOverdue
                          ? Colors.red.withOpacity(0.2)
                          : todo.isDueToday
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: todo.isOverdue
                            ? Colors.red
                            : todo.isDueToday
                                ? Colors.orange
                                : Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          todo.isOverdue
                              ? Icons.warning
                              : Icons.calendar_today,
                          size: 12,
                          color: todo.isOverdue
                              ? Colors.red
                              : todo.isDueToday
                                  ? Colors.orange
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yyyy').format(todo.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: todo.isOverdue
                                ? Colors.red
                                : todo.isDueToday
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Due Date Button
            IconButton(
              icon: Icon(
                todo.dueDate != null
                    ? Icons.event_available
                    : Icons.event,
                size: 20,
                color: todo.dueDate != null
                    ? (todo.isOverdue ? Colors.red : Colors.blue)
                    : Colors.grey,
              ),
              onPressed: () => _showDueDatePicker(todo),
              tooltip: 'Fälligkeitsdatum',
            ),
            // Priority Menu
            PopupMenuButton<TodoPriority>(
              icon: Icon(
                Icons.flag,
                color: todo.priority.color,
                size: 20,
              ),
              tooltip: 'Priorität ändern',
              onSelected: (priority) {
                ref.read(todoProvider.notifier).updateTodoPriority(
                      todo.id,
                      priority,
                    );
              },
              itemBuilder: (context) => TodoPriority.values.map((priority) {
                return PopupMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: priority.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(priority.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
            // Edit Button
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
          ],
        ),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final controller = TextEditingController();
    TodoPriority selectedPriority = TodoPriority.normal;
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Neue Aufgabe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Aufgabe eingeben...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Priorität:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                children: TodoPriority.values.map((priority) {
                  final isSelected = selectedPriority == priority;
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  
                  // Adjust text color for better readability in dark mode
                  final textColor = isSelected 
                      ? Colors.white 
                      : (isDarkMode && priority == TodoPriority.normal)
                          ? Colors.black87  // Dark text for yellow in dark mode
                          : null;  // Use default theme color
                  
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: isSelected ? Colors.white : priority.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          priority.displayName,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedPriority = priority;
                      });
                    },
                    selectedColor: priority.color,
                    backgroundColor: priority.color.withOpacity(0.2),
                    side: BorderSide(color: priority.color),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Fälligkeitsdatum:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDueDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        selectedDueDate != null
                            ? DateFormat('dd.MM.yyyy').format(selectedDueDate!)
                            : 'Datum wählen',
                      ),
                    ),
                  ),
                  if (selectedDueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          selectedDueDate = null;
                        });
                      },
                      tooltip: 'Datum entfernen',
                    ),
                  ],
                ],
              ),
            ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(todoProvider.notifier).addTodo(
                        controller.text,
                        priority: selectedPriority,
                        dueDate: selectedDueDate,
                      );
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
      ),
    );
  }

  /// Show date picker to set or update due date for a todo
  Future<void> _showDueDatePicker(Todo todo) async {
    final date = await showDatePicker(
      context: context,
      initialDate: todo.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      await ref.read(todoProvider.notifier).updateTodoDueDate(todo.id, date);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fälligkeitsdatum auf ${DateFormat('dd.MM.yyyy').format(date)} gesetzt'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Entfernen',
              onPressed: () {
                ref.read(todoProvider.notifier).updateTodoDueDate(todo.id, null);
              },
            ),
          ),
        );
      }
    }
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
